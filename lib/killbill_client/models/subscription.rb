module KillBillClient
  module Model
    class Subscription < SubscriptionAttributesWithEvents
      has_many :events, KillBillClient::Model::Event

    end
  end
end
