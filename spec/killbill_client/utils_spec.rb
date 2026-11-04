require 'spec_helper'

describe KillBillClient::Utils do
  # Real attribute names, as sent by Kill Bill (camelCase) and as used by the models (snake_case)
  let(:camel_cased) do
    %w(accountId externalKey billCycleDayLocal accountCBA accountBalance isPaymentDelegatedToParent
       paymentMethodId referenceTime timeZone CBA HTTPResponse X-Killbill-ApiKey Foo::BarBaz already_underscored id)
  end
  let(:underscored) do
    %w(account_id external_key bill_cycle_day_local account_cba account_balance
       is_payment_delegated_to_parent payment_method_id reference_time time_zone cba id)
  end

  describe '.underscore' do
    {
      'accountId' => 'account_id',
      'accountCBA' => 'account_cba',
      'CBA' => 'cba',
      'HTTPResponse' => 'http_response',
      'X-Killbill-ApiKey' => 'x_killbill_api_key',
      'Foo::BarBaz' => 'foo/bar_baz',
      'already_underscored' => 'already_underscored',
      'id' => 'id',
      '' => ''
    }.each do |input, expected|
      it "converts #{input.inspect} to #{expected.inspect}" do
        expect(described_class.underscore(input)).to eq(expected)
      end
    end

    it 'accepts symbols and nil, like before' do
      expect(described_class.underscore(:accountId)).to eq('account_id')
      expect(described_class.underscore(nil)).to eq('')
    end

    it 'returns the same result as the uncached implementation' do
      camel_cased.each do |word|
        expect(described_class.underscore(word)).to eq(described_class.underscore_uncached(word))
      end
    end

    # The implementation from before the caching change, which used /([A-Z]+)([A-Z][a-z])/
    def original_underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr! '-', '_'
      word.downcase!
      word
    end

    it 'matches the original implementation on tricky and random inputs' do
      tricky = %w(HTTPResponse XMLHttpRequest ABCdEFg ABcDEf AbCDe AAAb aAAb A Aa AA AAa getHTTPStatusCode
                  account2FA x-Killbill-ApiKey Foo::BARBaz)
      tricky.each { |word| expect(described_class.underscore_uncached(word)).to eq(original_underscore(word)) }

      alphabet = ('A'..'Z').to_a + ('a'..'z').to_a + %w(0 1 _ - :)
      rng = Random.new(42)
      2_000.times do
        word = Array.new(rng.rand(1..14)) { alphabet[rng.rand(alphabet.size)] }.join
        expect(described_class.underscore_uncached(word)).to eq(original_underscore(word))
      end
    end

    it 'runs in linear time on long runs of capital letters' do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect(described_class.underscore_uncached('A' * 50_000)).to eq('a' * 50_000)
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 2
    end

    it 'is idempotent, so underscoring an already underscored name is a no-op' do
      camel_cased.each do |word|
        once = described_class.underscore(word)
        expect(described_class.underscore(once)).to eq(once)
      end
    end

    it 'returns a frozen, cached String' do
      first = described_class.underscore('paymentMethodId')
      expect(first).to be_frozen
      expect(described_class.underscore('paymentMethodId')).to be(first)
    end

    it 'is not affected by later changes to the input String' do
      input = +'subscriptionId'
      expect(described_class.underscore(input)).to eq('subscription_id')
      input << 'Suffix'
      expect(described_class.underscore('subscriptionId')).to eq('subscription_id')
      expect(described_class.underscore(input)).to eq('subscription_id_suffix')
    end
  end

  describe '.camelize' do
    {
      ['account_id', :upper] => 'AccountId',
      ['account_id', :lower] => 'accountId',
      ['account_cba', :lower] => 'accountCBA',
      ['cba', :upper] => 'CBA',
      ['bill_cycle_day_local', :lower] => 'billCycleDayLocal',
      ['id', :lower] => 'id'
    }.each do |(input, first_letter), expected|
      it "converts #{input.inspect} (#{first_letter}) to #{expected.inspect}" do
        expect(described_class.camelize(input, first_letter)).to eq(expected)
      end
    end

    it 'defaults to an upper case first letter' do
      expect(described_class.camelize('account_id')).to eq('AccountId')
    end

    it 'caches upper and lower case variants separately' do
      expect(described_class.camelize('tenant_id', :lower)).to eq('tenantId')
      expect(described_class.camelize('tenant_id', :upper)).to eq('TenantId')
      expect(described_class.camelize('tenant_id', :lower)).to eq('tenantId')
    end

    it 'returns the same result as the uncached implementation' do
      underscored.each do |word|
        [:upper, :lower].each do |first_letter|
          expect(described_class.camelize(word, first_letter)).to eq(described_class.camelize_uncached(word, first_letter))
        end
      end
    end

    it 'returns a frozen, cached String' do
      first = described_class.camelize('payment_id', :lower)
      expect(first).to be_frozen
      expect(described_class.camelize('payment_id', :lower)).to be(first)
    end
  end

  describe KillBillClient::Utils::ConversionCache do
    it 'computes a value once per key' do
      cache = described_class.new
      calls = 0
      2.times { expect(cache.fetch('a') { |k| calls += 1; k.upcase }).to eq('A') }
      expect(calls).to eq(1)
      expect(cache.size).to eq(1)
    end

    it 'stops caching once full, but keeps returning correct values' do
      cache = described_class.new(2)
      %w(a b c d).each { |k| expect(cache.fetch(k, &:upcase)).to eq(k.upcase) }
      expect(cache.size).to eq(2)
      expect(cache.fetch('d', &:upcase)).to eq('D')
    end

    it 'is safe to use from many threads at once' do
      cache = described_class.new
      words = (1..200).map { |i| "attributeName#{i}" }
      results = Array.new(8) do
        Thread.new { words.shuffle.map { |w| [w, cache.fetch(w) { |k| KillBillClient::Utils.underscore_uncached(k) }] } }
      end.map(&:value)

      results.each do |pairs|
        pairs.each { |w, v| expect(v).to eq(KillBillClient::Utils.underscore_uncached(w)) }
      end
      expect(cache.size).to eq(words.size)
    end
  end

  describe 'JSON round trip through the models' do
    it 'maps camelCase JSON keys to model attributes and back' do
      json = { 'accountId' => 'a1', 'externalKey' => 'ext', 'accountCBA' => 12.5, 'billCycleDayLocal' => 3,
               'unknownAttribute' => 'ignored' }.to_json

      account = KillBillClient::Model::Account.send(:from_json, KillBillClient::Model::Account, json)
      expect(account.account_id).to eq('a1')
      expect(account.external_key).to eq('ext')
      expect(account.account_cba).to eq(12.5)
      expect(account.bill_cycle_day_local).to eq(3)

      hash = account.to_hash
      expect(hash['accountId']).to eq('a1')
      expect(hash['accountCBA']).to eq(12.5)
      expect(hash['billCycleDayLocal']).to eq(3)
      expect(hash).not_to have_key('unknownAttribute')
    end
  end
end
