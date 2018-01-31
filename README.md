killbill-client-ruby
====================

Kill Bill Ruby client library.

Kill Bill compatibility
-----------------------

| Client version | Kill Bill version |
| -------------: | ----------------: |
| 0.x.y          | 0.16.z            |
| 1.x.y          | 0.18.z            |
| 2.x.y          | 0.19.z            |

Installation
------------

Get the [killbill-client](https://rubygems.org/gems/killbill-client) gem:

```
gem install killbill-client
```

Alternatively, add the dependency in your Gemfile:

```
gem 'killbill-client', '~> 1.0'
```

Examples
--------

Here is a snippet creating your first account and subscription:

```ruby
require 'killbill_client'

KillBillClient.url = 'http://127.0.0.1:8080'

# Multi-tenancy and RBAC credentials
options = {
  :username => 'admin',
  :password => 'password',
  :api_key => 'bob',
  :api_secret => 'lazar'
}

# Audit log data
user = 'me'
reason = 'Going through my first tutorial'
comment = 'I like it!'

# Create an account
account = KillBillClient::Model::Account.new
account.name = 'John Doe'
account.first_name_length = 4
account.external_key = 'john-doe'
account.currency = 'USD'
account = account.create(user, reason, comment, options)

# Add a subscription
subscription = KillBillClient::Model::Subscription.new
subscription.account_id = account.account_id
subscription.product_name = 'Sports'
subscription.product_category = 'BASE'
subscription.billing_period = 'MONTHLY'
subscription.price_list = 'DEFAULT'
subscription = subscription.create(user, reason, comment, nil, true, options)

# List invoices
account.invoices(true, options).each do |invoice|
  puts invoice.inspect
end
```

The following script will tag a list of accounts with OVERDUE_ENFORCEMENT_OFF and AUTO_PAY_OFF:

```ruby
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

We have lots of examples in our [integration tests](https://github.com/killbill/killbill-integration-tests).

Tests
-----

To run the integration tests:

```bash
rake test:remote:spec
```

You need to set in spec/spec_helper.rb the url of your instance, e.g. `KillBillClient.url = 'http://127.0.0.1:8080'` and the username and password to authenticate the API, e.g. `KillBillClient.username = 'admin'` and `KillBillClient.password = 'password'`

## License

The Kill Bill Ruby client is released under the [Apache license](http://www.apache.org/licenses/LICENSE-2.0).
