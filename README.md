[![Build Status](https://travis-ci.org/killbill/killbill-client-ruby.png)](https://travis-ci.org/killbill/killbill-client-ruby)
[![Code Climate](https://codeclimate.com/github/killbill/killbill-client-ruby.png)](https://codeclimate.com/github/killbill/killbill-client-ruby)

killbill-client-ruby
====================

Kill Bill ruby library.

Examples
--------

The following script will tag a list of accounts with OVERDUE_ENFORCEMENT_OFF and AUTO_PAY_OFF:

```
require 'killbill_client'

KillBillClient.url = 'http://127.0.0.1:8080'

AUDIT_USER = 'pierre (via ruby script)'

File.open(File.dirname(__FILE__) + '/accounts.txt').readlines.map(&:chomp).each do |kb_account_id|
  account = KillBillClient::Model::Account.find_by_id kb_account_id
  puts "Current tags for #{account.name} (#{account.account_id}): #{account.tags.map(&:tag_definition_name).join(', ')}"

  account.add_tag 'OVERDUE_ENFORCEMENT_OFF', AUDIT_USER
  account.add_tag 'AUTO_PAY_OFF', AUDIT_USER

  puts "New tags for #{account.name} (#{account.account_id}): #{account.tags.map(&:tag_definition_name).join(', ')}"
end
```

Tests
-----

To run the integration tests:

```
rake test:remote:spec
```

You need to set in spec/spec_helper.rb the url of your instance, e.g. `KillBillClient.url = 'http://127.0.0.1:8080'`.
