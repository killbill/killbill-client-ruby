require 'spec_helper'

describe KillBillClient::Model::Resource do

  it 'should be able to be instantiated from hash' do
    payment1 = KillBillClient::Model::InvoicePayment.new
    payment1.account_id = '1234'
    payment1.target_invoice_id = '5678'
    payment1.purchased_amount = 12.42

    payment2 = KillBillClient::Model::InvoicePayment.new(payment1.to_hash)

    payment2.should == payment1
    payment2.account_id.should == '1234'
    payment2.target_invoice_id.should == '5678'
    payment2.purchased_amount.should == 12.42
  end

  describe '#require_multi_tenant_options!' do
    let(:message) { 'nothing' }

    def require_multi_tenant_options!
      described_class.require_multi_tenant_options!(options, message)
    end

    context 'when api_key and api_secret passed as options' do
      let(:options) do
        {
          api_key: 'bob',
          api_secret: 'lazar'
        }
      end

      it do
        expect { require_multi_tenant_options! }.not_to raise_error
      end
    end

    context 'when no api_key passed as options' do
      let(:options) do
        {
          api_secret: 'lazar'
        }
      end

      it do
        expect { require_multi_tenant_options! }.to raise_error(ArgumentError, message)
      end
    end

    context 'when no api_secret passed as options' do
      let(:options) do
        {
          api_key: 'bob'
        }
      end

      it do
        expect { require_multi_tenant_options! }.to raise_error(ArgumentError, message)
      end
    end

    context 'when api_key and api_secret passed as KillBillClient configuration option' do
      let(:options) { { } }
      before do
        KillBillClient.stub(:api_key) { 'bob' }
        KillBillClient.stub(:api_secret) { 'lazar' }
      end

      it do
        expect { require_multi_tenant_options! }.not_to raise_error
      end
    end
  end
end
