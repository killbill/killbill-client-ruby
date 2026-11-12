require 'spec_helper'

describe KillBillClient::Model::Resource do

  it 'should be able to be instantiated from hash' do
    payment1 = KillBillClient::Model::InvoicePayment.new
    payment1.account_id = '1234'
    payment1.target_invoice_id = '5678'
    payment1.purchased_amount = 12.42

    payment2 = KillBillClient::Model::InvoicePayment.new(payment1.to_hash)

    expect(payment2).to eq(payment1)
    expect(payment2.account_id).to eq('1234')
    expect(payment2.target_invoice_id).to eq('5678')
    expect(payment2.purchased_amount).to eq(12.42)
  end

  before do
    KillBillClient.api_key = nil
    KillBillClient.api_secret = nil
  end

  describe '#require_multi_tenant_options!' do
    let(:message) { 'nothing' }

    def require_multi_tenant_options!
      described_class.require_multi_tenant_options!(options, message)
    end

    context 'when api_key and api_secret passed as options' do
      let(:options) do
        {
          :api_key => 'bob',
          :api_secret =>'lazar'
        }
      end

      it do
        expect { require_multi_tenant_options! }.not_to raise_error
      end
    end

    context 'when no api_key passed as options' do
      let(:options) do
        {
          :api_secret => 'lazar'
        }
      end

      it do
        expect { require_multi_tenant_options! }.to raise_error(ArgumentError, message)
      end
    end

    context 'when no api_secret passed as options' do
      let(:options) do
        {
          :api_key => 'bob'
        }
      end

      it do
        expect { require_multi_tenant_options! }.to raise_error(ArgumentError, message)
      end
    end

    context 'when api_key and api_secret passed as KillBillClient configuration option' do
      let(:options) { { } }
      before do
        allow(KillBillClient).to receive_messages(:api_key => 'bob')
        allow(KillBillClient).to receive_messages(:api_secret => 'lazar')
      end

      it do
        expect { require_multi_tenant_options! }.not_to raise_error
      end
    end
  end

  describe '.from_json' do
    let(:json) do
      {
        'accountId' => 'abcd',
        'accountCBA' => 12.5,
        'externalKey' => 'ext',
        'unknownAttribute' => 'ignored',
        'auditLogs' => [{ 'changeType' => 'INSERT', 'changeDate' => '2024-01-01' }]
      }.to_json
    end

    it 'maps camelCased JSON keys onto attributes, including nested resources and acronyms' do
      # Twice, to exercise both the cold and the cached paths
      2.times do
        account = described_class.from_json(KillBillClient::Model::Account, json)

        expect(account.account_id).to eq('abcd')
        expect(account.account_cba).to eq(12.5)
        expect(account.external_key).to eq('ext')
        expect(account.audit_logs.size).to eq(1)
        expect(account.audit_logs.first).to be_a(KillBillClient::Model::AuditLog)
        expect(account.audit_logs.first.change_type).to eq('INSERT')
      end
    end

    it 'round-trips through to_hash' do
      account = described_class.from_json(KillBillClient::Model::Account, json)
      hash = account.to_hash

      expect(hash['accountId']).to eq('abcd')
      expect(hash['accountCBA']).to eq(12.5)
      expect(KillBillClient::Model::Account.new(hash)).to eq(account)
    end
  end
end
