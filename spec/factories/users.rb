FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "ユーザー#{n}" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :it_staff do
      role { :it_staff }
    end

    trait :admin do
      role { :admin }
    end
  end
end