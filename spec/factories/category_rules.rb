FactoryBot.define do
  factory :category_rule do
    category
    sequence(:keyword) { |n| "keyword#{n}" }
  end
end
