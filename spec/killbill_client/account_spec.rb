require 'spec_helper'

describe KillBillClient::Model::Account do

  def json_response(body)
    response = Net::HTTPOK.new('1.1', '200', 'OK')
    response['Content-Type'] = 'application/json'
    response.instance_variable_set(:@read, true)
    response.instance_variable_set(:@body, body)
    response
  end

  describe '.paginated_invoices' do
    let(:account_id) { 'e6f0d4ab-0d2b-4a8f-9a5c-0a8f5b1c2d3e' }
    let(:uri) { "/1.0/kb/accounts/#{account_id}/invoices/pagination" }

    it 'does not request invoice components by default' do
      expect(KillBillClient::API).to receive(:get)
                                       .with(uri, {:offset => 0, :limit => 100, :audit => 'NONE'}, {:api_key => 'key'})
                                       .and_return(json_response('[]'))

      described_class.paginated_invoices(account_id, 0, 100, 'NONE', {:api_key => 'key'})
    end

    it 'requests invoice components when asked to' do
      expect(KillBillClient::API).to receive(:get)
                                       .with(uri, {:offset => 10, :limit => 50, :audit => 'NONE', :includeInvoiceComponents => true}, {:api_key => 'key'})
                                       .and_return(json_response('[{"invoiceId":"abc","amount":12.5,"balance":2.5}]'))

      invoices = described_class.paginated_invoices(account_id, 10, 50, 'NONE', {:api_key => 'key'}, true)

      expect(invoices.size).to eq(1)
      expect(invoices.first.amount).to eq(12.5)
      expect(invoices.first.balance).to eq(2.5)
    end
  end
end
