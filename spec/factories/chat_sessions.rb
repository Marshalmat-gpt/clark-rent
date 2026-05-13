FactoryBot.define do
  factory :chat_session do
    association :user
    messages { [] }
  end
end
