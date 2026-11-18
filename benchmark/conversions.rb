#!/usr/bin/env ruby
#
# Micro-benchmark for the hot path that turns Kill Bill JSON responses into models (and back):
# Utils.underscore / Utils.camelize and Resource.from_json / #to_hash.
#
# Only uses the standard library. Run it on two checkouts (e.g. master vs a branch) to compare:
#
#   ruby  -Ilib benchmark/conversions.rb
#   jruby -Ilib benchmark/conversions.rb
#
# ITERATIONS (default 20) and INVOICES (default 300, i.e. a large account) can be set in the environment.
# On CRuby the number of allocated objects per operation is reported too.

require 'json'
require 'killbill_client'

ITERATIONS = Integer(ENV['ITERATIONS'] || 20)
INVOICES = Integer(ENV['INVOICES'] || 300)
ITEMS_PER_INVOICE = 3
WARMUP_ROUNDS = 5

def json_hash_for(model_class, overrides = {})
  model_class.json_attributes.each_with_object({}) do |name, hash|
    hash[KillBillClient::Utils.camelize(name, :lower)] = "value-#{name}"
  end.merge(overrides)
end

# A list of invoices with items, shaped like GET /1.0/kb/accounts/{id}/invoices?withItems=true
invoices = Array.new(INVOICES) do |i|
  items = Array.new(ITEMS_PER_INVOICE) { |j| json_hash_for(KillBillClient::Model::InvoiceItem, 'amount' => j * 10.0) }
  json_hash_for(KillBillClient::Model::Invoice, 'amount' => i * 1.5, 'items' => items, 'credits' => [], 'auditLogs' => [])
end
INVOICES_JSON = JSON.generate(invoices)
KEYS = (KillBillClient::Model::Invoice.json_attributes + KillBillClient::Model::InvoiceItem.json_attributes +
        KillBillClient::Model::Account.json_attributes).uniq.map { |n| KillBillClient::Utils.camelize(n, :lower) }

def allocated_objects
  GC.respond_to?(:stat) && GC.stat.key?(:total_allocated_objects) ? GC.stat(:total_allocated_objects) : nil
end

def measure(label, ops_per_iteration)
  WARMUP_ROUNDS.times { yield }
  before_allocs = allocated_objects
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  ITERATIONS.times { yield }
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  after_allocs = allocated_objects

  ops = ITERATIONS * ops_per_iteration
  line = format('%-42s %10.1f ms/iter %12.0f ops/s', label, elapsed * 1000 / ITERATIONS, ops / elapsed)
  line += format(' %10.1f objs/op', (after_allocs - before_allocs).to_f / ops) if before_allocs && after_allocs
  puts line
end

puts "#{RUBY_ENGINE} #{RUBY_ENGINE == 'jruby' ? JRUBY_VERSION : RUBY_VERSION}, killbill-client #{KillBillClient::VERSION}, " \
     "#{INVOICES} invoices x #{ITEMS_PER_INVOICE} items (#{INVOICES_JSON.bytesize / 1024} KiB of JSON), #{ITERATIONS} iterations"

measure("Utils.underscore (#{KEYS.size} keys x 1000)", KEYS.size * 1000) do
  1000.times { KEYS.each { |k| KillBillClient::Utils.underscore(k) } }
end

records = nil
measure('Resource.from_json (invoice list)', INVOICES) do
  records = KillBillClient::Model::Resource.send(:from_json, KillBillClient::Model::Invoice, INVOICES_JSON)
end

measure('Resource#to_hash (invoice list)', INVOICES) do
  records.each(&:to_hash)
end
