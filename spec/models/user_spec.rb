require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    subject { build(:user) }

    it "ファクトリで作ったユーザーは有効" do
      expect(subject).to be_valid
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email_address) }

    it "メールアドレスは大文字小文字を区別せず、重複を許さない" do
      create(:user, email_address: "taro@example.com")
      duplicate = build(:user, email_address: "TARO@example.com")
      expect(duplicate).not_to be_valid
    end

    it "パスワードは8文字未満だと無効" do
      expect(build(:user, password: "a" * 7)).not_to be_valid
    end

    it "パスワードは8文字以上なら有効" do
      expect(build(:user, password: "a" * 8)).to be_valid
    end
  end

  describe "メールアドレスの正規化" do
    it "前後の空白を取り除き、小文字にして保存する" do
      user = create(:user, email_address: "  Taro@Example.COM ")
      expect(user.email_address).to eq "taro@example.com"
    end
  end

  describe "ロール" do
    it "employee、it_staff、adminの3種類がある" do
      expect(User.roles).to eq("employee" => 0, "it_staff" => 1, "admin" => 2)
    end

    it "初期値はemployee" do
      expect(User.new.role).to eq "employee"
    end

    it "存在しないロールは無効になる" do
      expect(build(:user, role: "boss")).not_to be_valid
    end
  end

  describe "#staff?" do
    it "一般社員はfalse" do
      expect(build(:user).staff?).to be false
    end

    it "IT担当者はtrue" do
      expect(build(:user, :it_staff).staff?).to be true
    end

    it "管理者はtrue" do
      expect(build(:user, :admin).staff?).to be true
    end
  end
end
