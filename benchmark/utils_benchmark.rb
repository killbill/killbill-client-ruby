# Micro-benchmark for the JSON key conversions done on every Kill Bill response.
#
#   gem install benchmark-ips
#   ruby benchmark/utils_benchmark.rb
#
# It reports iterations/second (benchmark-ips) and objects allocated per iteration for:
#   * Utils.underscore / Utils.camelize on real Kill Bill attribute names
#   * Resource.from_json / Resource#to_hash on an account-timeline-like payload
#
# To compare against another revision, run it from a checkout of that revision (the script only uses APIs that
# exist on master) and compare the outputs.

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'json'
require 'killbill_client'

begin
  require 'benchmark/ips'
rescue LoadError
  abort 'benchmark-ips is required: gem install benchmark-ips'
end

# Attribute names as they appear on the wire (a representative sample of the models in lib/killbill_client/models/gen)
KEYS = %w(
  accountId name firstNameLength externalKey email billCycleDayLocal currency parentAccountId isPaymentDelegatedToParent
  paymentMethodId referenceTime timeZone address1 address2 postalCode company city state country locale phone notes
  isMigrated accountBalance accountCBA auditLogs invoiceItemId invoiceId linkedInvoiceItemId childAccountId bundleId
  subscriptionId productName planName phaseName usageName prettyProductName prettyPlanName prettyPhaseName
  prettyUsageName itemType description startDate endDate amount rate quantity itemDetails catalogEffectiveDate
  childItems invoiceDate targetDate invoiceNumber balance bundleKeys creditAdj refundAdj credits items trackingIds
  isParentInvoice parentInvoiceId eventId billingPeriod effectiveDate plan product priceList eventType
  isBlockedBilling isBlockedEntitlement serviceName serviceStateName phase paymentId paymentNumber paymentExternalKey
  authAmount capturedAmount purchasedAmount refundedAmount creditedAmount transactions paymentAttempts
  targetInvoiceId changeType changeDate
).freeze

SNAKE_KEYS = KEYS.map { |key| KillBillClient::Utils.underscore(key).dup }.freeze

def allocations
  GC.stat[:total_allocated_objects]
end

# Objects allocated per call, or nil when the runtime does not expose the counter (e.g. JRuby)
def allocations_per_call(iterations = 200)
  before = allocations
  return nil if before.nil?

  iterations.times { yield }
  (allocations - before) / iterations.to_f
end

def report(label, &block)
  # Warm up (also fills the caches, if any), then measure
  50.times(&block)
  allocated = allocations_per_call(&block)
  puts format('%-34s %s', label, allocated ? format('%.1f objects/iteration', allocated) : 'allocations: n/a on this runtime')
end

def timeline_json(accounts_items = 40)
  audit = [{ 'changeType' => 'INSERT', 'changeDate' => '2024-01-01T00:00:00.000Z', 'objectType' => 'INVOICE',
             'changedBy' => 'admin', 'reasonCode' => nil, 'comments' => nil, 'userToken' => 'token' }]
  item = lambda do |i|
    { 'invoiceItemId' => "item-#{i}", 'invoiceId' => 'inv', 'accountId' => 'acc', 'bundleId' => 'b', 'subscriptionId' => 's',
      'productName' => 'Standard', 'planName' => 'standard-monthly', 'phaseName' => 'standard-monthly-evergreen',
      'prettyProductName' => 'Standard', 'prettyPlanName' => 'Standard Monthly', 'prettyPhaseName' => 'Standard Monthly Evergreen',
      'itemType' => 'RECURRING', 'startDate' => '2024-01-01', 'endDate' => '2024-02-01', 'amount' => 10.0, 'rate' => 10.0,
      'currency' => 'USD', 'quantity' => 1, 'auditLogs' => audit }
  end
  invoice = lambda do |i|
    { 'amount' => 10.0, 'currency' => 'USD', 'status' => 'COMMITTED', 'creditAdj' => 0.0, 'refundAdj' => 0.0,
      'invoiceId' => "inv-#{i}", 'invoiceDate' => '2024-01-01', 'targetDate' => '2024-01-01', 'invoiceNumber' => i.to_s,
      'balance' => 0.0, 'accountId' => 'acc', 'bundleKeys' => 'k', 'credits' => [], 'items' => Array.new(4) { |j| item.call(j) },
      'isParentInvoice' => false, 'auditLogs' => audit }
  end
  bundle = lambda do |i|
    { 'accountId' => 'acc', 'bundleId' => "b-#{i}", 'externalKey' => "key-#{i}", 'auditLogs' => audit,
      'subscriptions' => [{ 'accountId' => 'acc', 'bundleId' => "b-#{i}", 'subscriptionId' => "s-#{i}", 'externalKey' => "key-#{i}",
                            'startDate' => '2024-01-01', 'productName' => 'Standard', 'productCategory' => 'BASE',
                            'billingPeriod' => 'MONTHLY', 'phaseType' => 'EVERGREEN', 'priceList' => 'DEFAULT',
                            'planName' => 'standard-monthly', 'state' => 'ACTIVE', 'sourceType' => 'NATIVE',
                            'billingStartDate' => '2024-01-01', 'billCycleDayLocal' => 1, 'auditLogs' => audit,
                            'events' => Array.new(3) { |j| { 'eventId' => "e-#{j}", 'billingPeriod' => 'MONTHLY',
                                                             'effectiveDate' => '2024-01-01', 'plan' => 'standard-monthly',
                                                             'product' => 'Standard', 'priceList' => 'DEFAULT',
                                                             'eventType' => 'START_ENTITLEMENT', 'isBlockedBilling' => false,
                                                             'isBlockedEntitlement' => false, 'serviceName' => 'entitlement-service',
                                                             'serviceStateName' => 'ENT_STARTED', 'phase' => 'standard-monthly-evergreen',
                                                             'auditLogs' => audit } } }] }
  end
  payment = lambda do |i|
    { 'accountId' => 'acc', 'paymentId' => "p-#{i}", 'paymentNumber' => i.to_s, 'paymentExternalKey' => "pk-#{i}",
      'authAmount' => 0, 'capturedAmount' => 10.0, 'purchasedAmount' => 10.0, 'refundedAmount' => 0, 'creditedAmount' => 0,
      'currency' => 'USD', 'paymentMethodId' => 'pm', 'transactions' => [], 'auditLogs' => audit }
  end

  {
    'account' => { 'accountId' => 'acc', 'name' => 'John Doe', 'externalKey' => 'ext', 'email' => 'john@example.com',
                   'billCycleDayLocal' => 0, 'currency' => 'USD', 'isPaymentDelegatedToParent' => false,
                   'timeZone' => 'UTC', 'country' => 'US', 'isMigrated' => false, 'accountBalance' => 0, 'accountCBA' => 0,
                   'auditLogs' => audit },
    'bundles' => Array.new(accounts_items / 4) { |i| bundle.call(i) },
    'invoices' => Array.new(accounts_items) { |i| invoice.call(i) },
    'payments' => Array.new(accounts_items) { |i| payment.call(i) }
  }.to_json
end

JSON_PAYLOAD = timeline_json.freeze

puts "#{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_DESCRIPTION})"
puts "#{KEYS.size} distinct attribute names; timeline payload: #{JSON_PAYLOAD.bytesize} bytes"
puts

puts 'Allocations'
report('underscore (all keys)') { KEYS.each { |key| KillBillClient::Utils.underscore(key) } }
report('camelize :lower (all keys)') { SNAKE_KEYS.each { |key| KillBillClient::Utils.camelize(key, :lower) } }
report('from_json (account timeline)') { KillBillClient::Model::Resource.from_json(KillBillClient::Model::AccountTimeline, JSON_PAYLOAD) }
TIMELINE = KillBillClient::Model::Resource.from_json(KillBillClient::Model::AccountTimeline, JSON_PAYLOAD)
report('to_hash (account timeline)') { TIMELINE.to_hash }
puts

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('underscore (all keys)') { KEYS.each { |key| KillBillClient::Utils.underscore(key) } }
  x.report('camelize :lower (all keys)') { SNAKE_KEYS.each { |key| KillBillClient::Utils.camelize(key, :lower) } }
  x.report('from_json (account timeline)') { KillBillClient::Model::Resource.from_json(KillBillClient::Model::AccountTimeline, JSON_PAYLOAD) }
  x.report('to_hash (account timeline)') { TIMELINE.to_hash }
end
