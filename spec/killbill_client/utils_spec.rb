require 'spec_helper'

describe KillBillClient::Utils do
  describe '.underscore' do
    {
      'accountId' => 'account_id',
      'AccountId' => 'account_id',
      'invoiceID' => 'invoice_id',
      'HTTPServer' => 'http_server',
      'ABCde' => 'ab_cde',
      'ABcDEf' => 'a_bc_d_ef',
      'accountCBAId' => 'account_cba_id',
      'already_underscored' => 'already_underscored',
      'some-dashed-key' => 'some_dashed_key',
      'Foo::BarBaz' => 'foo/bar_baz',
      'plan2Name' => 'plan2_name',
      '' => ''
    }.each do |input, expected|
      it "converts #{input.inspect} to #{expected.inspect}" do
        expect(described_class.underscore(input)).to eq(expected)
      end
    end

    it 'accepts symbols' do
      expect(described_class.underscore(:accountId)).to eq('account_id')
    end

    it 'does not mutate its argument' do
      input = 'accountId'
      described_class.underscore(input)
      expect(input).to eq('accountId')
    end

    it 'runs in linear time on long runs of capital letters' do
      # The previous regex took several seconds on this input
      started = Time.now
      described_class.underscore('A' * 200_000 + '!')
      expect(Time.now - started).to be < 1
    end
  end
end
