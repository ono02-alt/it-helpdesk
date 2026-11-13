require "rails_helper"

RSpec.describe CategoryRule, type: :model do
  it { is_expected.to belong_to(:category) }
  it { is_expected.to validate_presence_of(:keyword) }

  it "同じカテゴリに、同じキーワードは登録できない" do
    rule = create(:category_rule, keyword: "VPN")
    duplicate = build(:category_rule, category: rule.category, keyword: "VPN")
    expect(duplicate).not_to be_valid
  end

  it "別のカテゴリなら、同じキーワードを登録できる" do
    create(:category_rule, keyword: "VPN")
    expect(build(:category_rule, keyword: "VPN")).to be_valid
  end
end
