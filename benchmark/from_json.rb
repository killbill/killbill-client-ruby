# Benchmark for Resource.from_json / instantiate_record_from_json and Utils.underscore.
#
#   ruby -Ilib benchmark/from_json.rb                      # synthetic payloads
#   PAYLOAD_DIR=/path/to/captures ruby -Ilib benchmark/from_json.rb
#
# PAYLOAD_DIR: JSON files captured from a real Kill Bill (e.g. with curl), named
# <ModelName>.<anything>.json, where ModelName is a class under KillBillClient::Model
# (e.g. Account.json, Invoice.list.json, InvoicePayment.list.json, AccountTimeline.json).
# Without it, payloads are generated from the models' declared attributes (plus a few
# unknown fields), which is only a rough stand-in for real responses.
#
# Needs the benchmark-ips gem (gem install benchmark-ips).
require 'json'
require 'benchmark/ips'
require 'killbill_client'

Resource = KillBillClient::Model::Resource
Model = KillBillClient::Model

UNKNOWN_FIELDS = { 'someNewField' => 'x', 'anotherUnknownField' => 42 }.freeze

def camel(name)
  KillBillClient::Utils.camelize(name, :lower)
end

# Fills every declared attribute (and has_one/has_many, down to `depth`) of a model.
def synthetic(clazz, depth = 2)
  nested = Resource.class_variable_get(:@@attribute_names)
  hash = {}
  clazz.ancestors.each do |ancestor|
    (ancestor.respond_to?(:json_attributes) ? ancestor.json_attributes : []).each { |attr| hash[camel(attr)] ||= "#{attr}-value" }
    (nested[ancestor.name] || {}).each do |attr, desc|
      next if desc[:type].nil? || depth.zero?
      child = synthetic(desc[:type], depth - 1)
      hash[camel(attr)] = desc[:cardinality] == :many ? [child, child] : child
    end
  end
  hash.merge(UNKNOWN_FIELDS)
end

def synthetic_list(clazz, n)
  Array.new(n) { synthetic(clazz, 1) }
end

def synthetic_timeline(n)
  synthetic(Model::AccountTimeline, 0).merge(
    'account' => synthetic(Model::Account, 0),
    'invoices' => synthetic_list(Model::Invoice, n),
    'payments' => synthetic_list(Model::InvoicePayment, n),
    'bundles' => synthetic_list(Model::Bundle, n / 10)
  )
end

def load_payloads
  dir = ENV['PAYLOAD_DIR']
  if dir
    Dir[File.join(dir, '*.json')].sort.map do |file|
      [File.basename(file, '.json'), Model.const_get(File.basename(file).split('.').first), File.read(file)]
    end
  else
    [
      ['Account (synthetic)', Model::Account, synthetic(Model::Account, 0).to_json],
      ['Invoice list x50 (synthetic)', Model::Invoice, synthetic_list(Model::Invoice, 50).to_json],
      ['InvoicePayment list x50 (synthetic)', Model::InvoicePayment, synthetic_list(Model::InvoicePayment, 50).to_json],
      ['AccountTimeline, 300 invoices/payments (synthetic)', Model::AccountTimeline, synthetic_timeline(300).to_json]
    ]
  end
end

def allocations
  GC.stat[:total_allocated_objects].to_i
end

payloads = load_payloads
puts "#{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_PLATFORM}), killbill_client #{KillBillClient::VERSION}"
puts

puts 'Per payload: size, objects allocated per parse (CRuby only), exceptions raised per parse'
payloads.each do |label, clazz, json|
  Resource.from_json(clazz, json) # warm up (fills caches, if any)

  raised = Hash.new(0)
  trace = TracePoint.new(:raise) { |tp| raised[tp.raised_exception.class] += 1 }
  before = allocations
  trace.enable { Resource.from_json(clazz, json) }
  allocated = allocations - before

  printf("  %-55s %8d bytes  %9s allocations  exceptions: %s\n", label, json.bytesize,
         allocated.zero? ? 'n/a' : allocated, raised.empty? ? 0 : raised.inspect)
end
puts

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 3)
  payloads.each do |label, clazz, json|
    x.report("from_json #{label}") { Resource.from_json(clazz, json) }
  end
  x.report('Utils.underscore (camelCase key)') { KillBillClient::Utils.underscore('invoicePaymentId') }
  x.report('Utils.underscore (already underscored)') { KillBillClient::Utils.underscore('invoice_payment_id') }
end
