class Category < ApplicationRecord
  has_many :tickets, dependent: :nullify
  has_many :category_rules, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
