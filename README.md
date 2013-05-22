[![Build Status](https://travis-ci.org/killbill/killbill-client-ruby.png)](https://travis-ci.org/killbill/killbill-client-ruby)
[![Code Climate](https://codeclimate.com/github/killbill/killbill-client-ruby.png)](https://codeclimate.com/github/killbill/killbill-client-ruby)

killbill-client-ruby
====================

Kill Bill ruby library.

Tests
-----

To run the integration tests:

```
rake test:remote:spec
```

You need to set in spec/spec_helper.rb the url of your instance, e.g. `KillBillClient.url = 'http://127.0.0.1:8080'`.
