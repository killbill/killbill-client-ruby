module KillBillClient
  module Model
    class SubscriptionEvent < SubscriptionAttributesNoEvents
      has_many :events, KillBillClient::Model::Event
      has_many :deleted_events, KillBillClient::Model::SubscriptionDeletedEvent
      has_many :new_events, KillBillClient::Model::SubscriptionNewEvent
    end
  end
end
