FactoryBot.define do
  factory :ticket do
    sequence(:title) { |n| "問い合わせ#{n}" }
    body { "パスワードを忘れてログインできません。" }
    association :requester, factory: :user

    trait :in_progress do
      association :assignee, factory: [ :user, :it_staff ]
      status { :in_progress }
    end

    trait :resolved do
      association :assignee, factory: [ :user, :it_staff ]
      status { :resolved }
    end

    trait :closed do
      association :assignee, factory: [ :user, :it_staff ]
      status { :closed }
    end
  end
end
