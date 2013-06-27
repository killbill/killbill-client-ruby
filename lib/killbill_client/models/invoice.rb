module KillBillClient
  module Model
    class Invoice < InvoiceAttributesSimple
      KILLBILL_API_INVOICES_PREFIX = "#{KILLBILL_API_PREFIX}/invoices"
    end
  end
end
