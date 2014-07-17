module KillBillClient
  module Model
    class Phase < PhaseAttributes

      has_many :prices, KillBillClient::Model::PriceAttributes

    end
  end
end
