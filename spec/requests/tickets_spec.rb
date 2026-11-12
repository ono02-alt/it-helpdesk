require "rails_helper"

RSpec.describe "Tickets", type: :request do
  let(:employee) { create(:user) }
  let(:other_employee) { create(:user) }
  let(:staff) { create(:user, :it_staff) }

  describe "未ログインのとき" do
    it "一覧はログイン画面へ移動する" do
      get tickets_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /tickets" do
    let!(:own_ticket) { create(:ticket, title: "自分の問い合わせ", requester: employee) }
    let!(:others_ticket) { create(:ticket, title: "他人の問い合わせ", requester: other_employee) }

    it "一般社員には、自分の問い合わせだけ表示される" do
      sign_in employee
      get tickets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("自分の問い合わせ")
      expect(response.body).not_to include("他人の問い合わせ")
    end

    it "IT担当者には、全件表示される" do
      sign_in staff
      get tickets_path
      expect(response.body).to include("自分の問い合わせ")
      expect(response.body).to include("他人の問い合わせ")
    end
  end

  describe "GET /tickets/:id" do
    let(:ticket) { create(:ticket, requester: employee) }

    it "依頼者本人は見られる" do
      sign_in employee
      get ticket_path(ticket)
      expect(response).to have_http_status(:ok)
    end

    it "他の一般社員には見えない(404)" do
      sign_in other_employee
      get ticket_path(ticket)
      expect(response).to have_http_status(:not_found)
    end

    it "IT担当者は見られる" do
      sign_in staff
      get ticket_path(ticket)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /tickets" do
    let(:valid_params) do
      { ticket: { title: "VPNにつながらない", body: "自宅から接続できません。", priority: "high" } }
    end

    before { sign_in employee }

    it "ログインユーザーを依頼者として登録する" do
      expect { post tickets_path, params: valid_params }.to change(Ticket, :count).by(1)

      ticket = Ticket.last
      expect(ticket.requester).to eq employee
      expect(ticket.status).to eq "received"
      expect(response).to redirect_to(ticket_path(ticket))
    end

    it "依頼者を他人に偽装できない" do
      spoofed = valid_params.deep_merge(ticket: { requester_id: other_employee.id })
      post tickets_path, params: spoofed
      expect(Ticket.last.requester).to eq employee
    end

    it "件名が空なら登録されず、422を返す" do
      invalid = { ticket: { title: "", body: "内容" } }
      expect { post tickets_path, params: invalid }.not_to change(Ticket, :count)
      expect(response).to have_http_status(422)
    end
  end
end