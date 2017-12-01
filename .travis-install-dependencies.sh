#!/usr/bin/env sh

sudo sysctl -w net.ipv4.tcp_fin_timeout=15
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

if [ "$DB_ADAPTER" = 'mysql2' ] || [ "$DB_ADAPTER" = 'mariadb' ]; then
  mysql -u $DB_USER -e 'create database killbill;'
  curl 'http://docs.killbill.io/0.18/ddl.sql' | mysql -u $DB_USER killbill
elif [ "$DB_ADAPTER" = 'postgresql' ]; then
  psql -U $DB_USER -c 'create database killbill;'
  curl 'https://raw.githubusercontent.com/killbill/killbill/master/util/src/main/resources/org/killbill/billing/util/ddl-postgresql.sql' | psql -U $DB_USER killbill
  curl 'https://raw.githubusercontent.com/killbill/killbill/master/util/src/main/resources/org/killbill/billing/util/ddl-postgresql.sql' | psql -U $DB_USER kaui_test
  curl 'http://docs.killbill.io/0.18/ddl.sql' | psql -U $DB_USER killbill
fi

if $(ruby -e'require "java"'); then
  # Somehow missing on JRuby-9
  gem install bundler
  bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}
else
  bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}
fi

curl -L -O https://search.maven.org/remotecontent?filepath=org/kill-bill/billing/installer/kpm/0.6.0/kpm-0.6.0-linux-x86_64.tar.gz
tar zxf kpm-0.6.0-linux-x86_64.tar.gz
kpm-0.6.0-linux-x86_64/kpm install

if [ "$DB_ADAPTER" = 'mysql2' ] || [ "$DB_ADAPTER" = 'mariadb' ]; then
  cat<<EOS >> conf/catalina.properties
org.killbill.dao.url=jdbc:mysql://127.0.0.1:$DB_PORT/killbill
org.killbill.billing.osgi.dao.url=jdbc:mysql://127.0.0.1:$DB_PORT/killbill
EOS
elif [ "$DB_ADAPTER" = 'postgresql' ]; then
  cat<<EOS >> conf/catalina.properties
org.killbill.dao.url=jdbc:postgresql://127.0.0.1:$DB_PORT/killbill
org.killbill.billing.osgi.dao.url=jdbc:postgresql://127.0.0.1:$DB_PORT/killbill
EOS
fi

cat<<EOS >> conf/catalina.properties
org.killbill.dao.user=$DB_USER
org.killbill.dao.password=
org.killbill.billing.osgi.dao.user=$DB_USER
org.killbill.billing.osgi.dao.password=
org.killbill.catalog.uri=SpyCarAdvanced.xml
org.killbill.server.test.mode=true
EOS

./bin/catalina.sh start

TIME_LIMIT=$(( $(date +%s) + 120 ))
RET=0
while [ $RET != 201 -a $(date +%s) -lt $TIME_LIMIT ] ; do
  RET=$(curl -s \
             -o /dev/null \
             -w "%{http_code}" \
             -X POST \
             -u 'admin:password' \
             -H 'Content-Type:application/json' \
             -H 'X-Killbill-CreatedBy:admin' \
             -d '{"apiKey":"bob", "apiSecret":"lazar"}' \
             "http://127.0.0.1:8080/1.0/kb/tenants?useGlobalDefault=true")
  tail -50 logs/catalina.out
  sleep 5
done

# For Travis debugging
echo "*** conf/catalina.properties"
cat conf/catalina.properties

echo "*** logs/catalina.out"
tail -50 logs/catalina.out
