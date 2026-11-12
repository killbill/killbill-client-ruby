require 'spec_helper'

describe KillBillClient::Utils do
  describe '.underscore' do
    {
      'accountId' => 'account_id',
      'accountCBA' => 'account_cba',
      'CBAAmount' => 'cba_amount',
      'HTTPResponseCode' => 'http_response_code',
      'invoice2Id' => 'invoice2_id',
      'a1B' => 'a1_b',
      'KillBillClient::Model::Account' => 'kill_bill_client/model/account',
      'billing-period' => 'billing_period',
      'Billing-Period' => 'billing_period',
      'ÉtatCivil' => 'état_civil',
      'already_underscored' => 'already_underscored',
      'lowercase' => 'lowercase',
      '' => ''
    }.each do |input, expected|
      it "converts #{input.inspect} to #{expected.inspect}" do
        expect(described_class.underscore(input)).to eq(expected)
      end
    end

    it 'accepts symbols and other objects responding to to_s' do
      expect(described_class.underscore(:accountId)).to eq('account_id')
      expect(described_class.underscore(nil)).to eq('')
      expect(described_class.underscore(42)).to eq('42')
    end

    it 'is idempotent' do
      %w(accountId accountCBA CBAAmount a1B billing-period KillBillClient::Model::Account).each do |input|
        once = described_class.underscore(input)
        expect(described_class.underscore(once)).to eq(once)
      end
    end

    it 'returns frozen strings, and caches them' do
      first = described_class.underscore('someFreshCamelCasedName')
      expect(first).to be_frozen
      expect(described_class.underscore('someFreshCamelCasedName')).to equal(first)
      expect(described_class.underscore('already_underscored_name')).to be_frozen
    end

    it 'does not alias or mutate its input' do
      input = +'accountId'
      result = described_class.underscore(input)
      input << 'Suffix'
      expect(result).to eq('account_id')
      expect(described_class.underscore('accountId')).to eq('account_id')
      expect(described_class.underscore(input)).to eq('account_id_suffix')
    end

    it 'is thread safe' do
      names = (0...200).map { |i| "someAttributeName#{i}Value" }
      results = 8.times.map do
        Thread.new { names.map { |name| described_class.underscore(name) } }
      end.map(&:value)

      expected = names.map { |name| name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase }
      results.each { |result| expect(result).to eq(expected) }
    end
  end

  describe '.underscore_symbols' do
    it 'returns the attribute name and its setter' do
      expect(described_class.underscore_symbols('accountCBA')).to eq([:account_cba, :account_cba=])
      expect(described_class.underscore_symbols(:accountId)).to eq([:account_id, :account_id=])
      expect(described_class.underscore_symbols('account_id')).to eq([:account_id, :account_id=])
    end

    it 'returns frozen, cached results' do
      first = described_class.underscore_symbols('anotherFreshName')
      expect(first).to be_frozen
      expect(described_class.underscore_symbols('anotherFreshName')).to equal(first)
    end
  end

  describe '.camelize' do
    {
      ['account_id'] => 'AccountId',
      ['account_id', :lower] => 'accountId',
      ['account_cba'] => 'AccountCBA',
      ['account_cba', :lower] => 'accountCBA',
      ['cba'] => 'CBA',
      # Legacy behavior, unchanged: the acronym is upcased before the first letter is lowered
      ['cba', :lower] => 'cBA',
      ['cba_amount', :lower] => 'cBAAmount',
      ['account'] => 'Account',
      ['account', :lower] => 'account',
      ['invoice2_id', :lower] => 'invoice2Id',
      ['accountId'] => 'AccountId',
      ['accountId', :lower] => 'accountId',
      [''] => ''
    }.each do |args, expected|
      it "converts #{args.inspect} to #{expected.inspect}" do
        expect(described_class.camelize(*args)).to eq(expected)
      end
    end

    it 'accepts symbols' do
      expect(described_class.camelize(:account_id, :lower)).to eq('accountId')
    end

    it 'caches upper and lower variants independently' do
      expect(described_class.camelize('some_name')).to eq('SomeName')
      expect(described_class.camelize('some_name', :lower)).to eq('someName')
      expect(described_class.camelize('some_name')).to eq('SomeName')
    end

    it 'returns frozen strings, and caches them' do
      first = described_class.camelize('some_fresh_name', :lower)
      expect(first).to be_frozen
      expect(described_class.camelize('some_fresh_name', :lower)).to equal(first)
    end

    it 'does not cache failures' do
      expect { described_class.camelize('', :lower) }.to raise_error(TypeError)
      expect { described_class.camelize('', :lower) }.to raise_error(TypeError)
    end
  end

  describe KillBillClient::Utils::Cache do
    it 'stops caching once full, but keeps computing correct values' do
      cache = described_class.new(2)
      calls = 0
      compute = lambda { |value| cache.fetch(value) { calls += 1; value.to_s * 2 } }

      expect(compute.call('a')).to eq('aa')
      expect(compute.call('b')).to eq('bb')
      expect(compute.call('c')).to eq('cc')
      expect(cache.size).to eq(2)
      expect(calls).to eq(3)

      expect(compute.call('a')).to eq('aa')
      expect(compute.call('c')).to eq('cc')
      expect(calls).to eq(4)
    end
  end
end
