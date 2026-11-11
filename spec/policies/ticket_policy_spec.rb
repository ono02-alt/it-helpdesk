require "rails_helper"

RSpec.describe TicketPolicy, type: :policy do
  subject { described_class }

  let(:requester) { create(:user) }
  let(:other_employee) { create(:user) }
  let(:staff) { create(:user, :it_staff) }
  let(:admin) { create(:user, :admin) }
  let(:ticket) { create(:ticket, requester: requester) }

  permissions :index?, :new?, :create? do
    it "全ロールに許可する" do
      [ requester, staff, admin ].each do |user|
        expect(subject).to permit(user, ticket)
      end
    end
  end

  permissions :show? do
    it "依頼者本人に許可する" do
      expect(subject).to permit(requester, ticket)
    end

    it "IT担当者に許可する" do
      expect(subject).to permit(staff, ticket)
    end

    it "管理者に許可する" do
      expect(subject).to permit(admin, ticket)
    end

    it "無関係の一般社員には許可しない" do
      expect(subject).not_to permit(other_employee, ticket)
    end
  end

  permissions :update? do
    it "IT担当者に許可する" do
      expect(subject).to permit(staff, ticket)
    end

    it "管理者に許可する" do
      expect(subject).to permit(admin, ticket)
    end

    it "依頼者本人でも、一般社員には許可しない" do
      expect(subject).not_to permit(requester, ticket)
    end

    it "他の一般社員にも許可しない" do
      expect(subject).not_to permit(other_employee, ticket)
    end
  end

  describe "Scope" do
    let!(:own_ticket) { create(:ticket, requester: requester) }
    let!(:others_ticket) { create(:ticket) }

    it "一般社員は自分の問い合わせだけ見える" do
      result = TicketPolicy::Scope.new(requester, Ticket).resolve
      expect(result).to contain_exactly(own_ticket)
    end

    it "IT担当者は全件見える" do
      result = TicketPolicy::Scope.new(staff, Ticket).resolve
      expect(result).to contain_exactly(own_ticket, others_ticket)
    end

    it "管理者は全件見える" do
      result = TicketPolicy::Scope.new(admin, Ticket).resolve
      expect(result).to contain_exactly(own_ticket, others_ticket)
    end
  end
end