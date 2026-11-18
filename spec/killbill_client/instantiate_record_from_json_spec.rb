require 'spec_helper'

# Test-only models (named, since has_one/has_many metadata is keyed by class name)
module InstantiateRecordSpec
  class Leaf < KillBillClient::Model::Resource
    attribute :id
    attribute :first_name
  end

  class Base < KillBillClient::Model::Resource
    attribute :name
    has_one :owner, Leaf
    has_many :leaves, Leaf
  end

  class Child < Base
    attribute :extra
    has_many :more_leaves, Leaf
  end
end

describe KillBillClient::Model::Resource do
  let(:leaf) { InstantiateRecordSpec::Leaf }
  let(:base) { InstantiateRecordSpec::Base }
  let(:child) { InstantiateRecordSpec::Child }

  def parse(clazz, hash)
    described_class.from_json(clazz, hash.to_json)
  end

  describe '.from_json / instantiate_record_from_json' do
    it 'maps camelCase keys to attributes' do
      record = parse(leaf, 'id' => 'a', 'firstName' => 'Bob')
      expect(record.id).to eq('a')
      expect(record.first_name).to eq('Bob')
    end

    it 'instantiates nested has_one' do
      record = parse(base, 'name' => 'n', 'owner' => { 'id' => 'o', 'firstName' => 'Ann' })
      expect(record.owner).to be_a(leaf)
      expect(record.owner.first_name).to eq('Ann')
    end

    it 'instantiates nested has_many, leaving non-hash elements untouched' do
      record = parse(base, 'leaves' => [{ 'id' => '1' }, { 'id' => '2' }, 'raw'])
      expect(record.leaves.map(&:class)).to eq([leaf, leaf, String])
      expect(record.leaves.first(2).map(&:id)).to eq(%w(1 2))
      expect(record.leaves.last).to eq('raw')
    end

    it 'does not instantiate when the JSON shape does not match the declaration' do
      record = parse(base, 'owner' => 'not-a-hash', 'leaves' => { 'id' => '1' })
      expect(record.owner).to eq('not-a-hash')
      expect(record.leaves).to eq({ 'id' => '1' })
    end

    it 'keeps null values' do
      record = parse(base, 'owner' => nil, 'leaves' => nil)
      expect(record.owner).to be_nil
      expect(record.leaves).to be_nil
    end

    it 'inherits has_one/has_many declarations from ancestors' do
      record = parse(child, 'name' => 'n', 'extra' => 'e',
                            'owner' => { 'id' => 'o' },
                            'leaves' => [{ 'id' => '1' }],
                            'moreLeaves' => [{ 'id' => '2' }])
      expect(record.name).to eq('n')
      expect(record.extra).to eq('e')
      expect(record.owner).to be_a(leaf)
      expect(record.leaves.first).to be_a(leaf)
      expect(record.more_leaves.first).to be_a(leaf)
    end

    it 'does not leak a subclass declaration to its parent' do
      record = parse(base, 'moreLeaves' => [{ 'id' => '2' }])
      expect(record).not_to respond_to(:more_leaves)
    end

    it 'ignores unknown fields' do
      record = parse(base, 'name' => 'n', 'doesNotExist' => 1, 'nested' => { 'a' => 1 })
      expect(record.name).to eq('n')
      expect(record).not_to respond_to(:does_not_exist)
    end

    it 'does not use exceptions as control flow for unknown fields' do
      parse(base, 'name' => 'warm-up', 'doesNotExist' => 1) # fill the cache

      raised = []
      trace = TracePoint.new(:raise) { |tp| raised << tp.raised_exception.class }
      trace.enable { parse(base, 'name' => 'n', 'doesNotExist' => 1, 'alsoUnknown' => 2) }

      expect(raised).to be_empty
    end

    it 'stays lenient when a setter raises' do
      klass = Class.new(KillBillClient::Model::Resource) do
        attribute :ok
        def boom=(_); raise 'boom'; end
      end
      record = described_class.from_json(klass, { 'ok' => 1, 'boom' => 2 }.to_json)
      expect(record.ok).to eq(1)
    end

    it 'parses arrays of records' do
      records = parse(base, [{ 'name' => 'a' }, { 'name' => 'b' }])
      expect(records.map(&:name)).to eq(%w(a b))
    end

    it 'picks up declarations added after a first parse' do
      klass = Class.new(KillBillClient::Model::Resource) { attribute :id }
      expect(described_class.from_json(klass, { 'id' => 1, 'late' => 2 }.to_json)).not_to respond_to(:late)

      klass.send(:attribute, :late)
      expect(described_class.from_json(klass, { 'id' => 1, 'late' => 2 }.to_json).late).to eq(2)
    end

    it 'is safe to use from several threads' do
      payload = { 'name' => 'n', 'owner' => { 'id' => 'o' }, 'leaves' => [{ 'id' => '1' }], 'unknownKey' => 1 }.to_json
      results = 8.times.map do
        Thread.new { 50.times.map { described_class.from_json(base, payload) } }
      end.flat_map(&:value)
      expect(results.map { |r| [r.name, r.owner.id, r.leaves.first.id] }.uniq).to eq([%w(n o 1)])
    end
  end

  it 'parses an AccountTimeline with real models' do
    json = {
      'account' => { 'accountId' => 'acc', 'name' => 'Bob' },
      'invoices' => [{ 'invoiceId' => 'i1', 'items' => [{ 'invoiceItemId' => 'it1' }] }],
      'payments' => [{ 'paymentId' => 'p1' }],
      'bundles' => [{ 'bundleId' => 'b1' }],
      'somethingNew' => true
    }.to_json
    timeline = described_class.from_json(KillBillClient::Model::AccountTimeline, json)
    expect(timeline.account).to be_a(KillBillClient::Model::Account)
    expect(timeline.account.account_id).to eq('acc')
    expect(timeline.invoices.first).to be_a(KillBillClient::Model::Invoice)
    expect(timeline.invoices.first.items.first).to be_a(KillBillClient::Model::InvoiceItem)
    expect(timeline.payments.first).to be_a(KillBillClient::Model::InvoicePayment)
    expect(timeline.bundles.first.bundle_id).to eq('b1')
  end
end
