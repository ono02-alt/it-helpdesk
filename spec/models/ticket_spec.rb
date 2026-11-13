require "rails_helper"

RSpec.describe Ticket, type: :model do
  describe "バリデーション" do
    subject { build(:ticket) }

    it "ファクトリで作ったチケットは有効" do
      expect(subject).to be_valid
    end

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_presence_of(:body) }

    it "依頼者がいないと無効" do
      expect(build(:ticket, requester: nil)).not_to be_valid
    end
  end

  describe "初期値" do
    it "ステータスはreceived" do
      expect(Ticket.new.status).to eq "received"
    end

    it "優先度はnormal" do
      expect(Ticket.new.priority).to eq "normal"
    end
  end

  describe "担当者" do
    it "一般社員は担当者にできない" do
      ticket = build(:ticket, assignee: create(:user))
      expect(ticket).not_to be_valid
    end

    it "IT担当者は担当者にできる" do
      ticket = build(:ticket, assignee: create(:user, :it_staff))
      expect(ticket).to be_valid
    end

    it "管理者は担当者にできる" do
      ticket = build(:ticket, assignee: create(:user, :admin))
      expect(ticket).to be_valid
    end
  end

  describe "ステータス遷移" do
    let(:staff) { create(:user, :it_staff) }

    it "担当者がいれば、receivedからin_progressにできる" do
      ticket = create(:ticket)
      ticket.assignee = staff
      ticket.status = :in_progress
      expect(ticket).to be_valid
    end

    it "担当者がいないと、in_progressにできない" do
      ticket = create(:ticket)
      ticket.status = :in_progress
      expect(ticket).not_to be_valid
    end

    it "receivedからresolvedへは直接変更できない" do
      ticket = create(:ticket)
      ticket.assignee = staff
      ticket.status = :resolved
      expect(ticket).not_to be_valid
    end

    it "in_progressからresolvedにできる" do
      ticket = create(:ticket, :in_progress)
      ticket.status = :resolved
      expect(ticket).to be_valid
    end

    it "resolvedからin_progressに戻せる(再オープン)" do
      ticket = create(:ticket, :resolved)
      ticket.status = :in_progress
      expect(ticket).to be_valid
    end

    it "closedからは変更できない" do
      ticket = create(:ticket, :closed)
      ticket.status = :in_progress
      expect(ticket).not_to be_valid
    end
  end

  describe "解決日時" do
    it "resolvedにすると記録される" do
      ticket = create(:ticket, :in_progress)
      expect(ticket.resolved_at).to be_nil
      ticket.update!(status: :resolved)
      expect(ticket.resolved_at).to be_present
    end

    it "再オープンすると消える" do
      ticket = create(:ticket, :resolved)
      ticket.update!(status: :in_progress)
      expect(ticket.resolved_at).to be_nil
    end

    it "closedにしても残る" do
      ticket = create(:ticket, :resolved)
      ticket.update!(status: :closed)
      expect(ticket.resolved_at).to be_present
    end
  end

  describe "自動分類" do
    let!(:account) { create(:category, name: "アカウント") }

    before { create(:category_rule, category: account, keyword: "パスワード") }

    it "作成時にカテゴリが空なら、本文から自動で設定される" do
      ticket = create(:ticket, body: "パスワードを忘れました")
      expect(ticket.category).to eq account
    end

    it "カテゴリを指定して作成した場合は、上書きしない" do
      other = create(:category)
      ticket = create(:ticket, body: "パスワードを忘れました", category: other)
      expect(ticket.category).to eq other
    end

    it "更新では自動分類しない" do
      ticket = create(:ticket, body: "関係のない内容")
      ticket.update!(body: "パスワードを忘れました")
      expect(ticket.category).to be_nil
    end
  end
end
