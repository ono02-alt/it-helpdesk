class CategoryRule < ApplicationRecord
  belongs_to :category

  validates :keyword, presence: true, uniqueness: { scope: :category_id }
end
