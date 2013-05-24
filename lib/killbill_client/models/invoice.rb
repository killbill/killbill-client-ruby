module KillBillClient
  module Model
    class Invoice < InvoiceAttributes
      KILLBILL_API_INVOICES_PREFIX = "#{KILLBILL_API_PREFIX}/invoices"
    end
  end
end
