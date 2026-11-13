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

    it "IT担当者には、更新フォームが表示される" do
      sign_in staff
      get ticket_path(ticket)
      expect(response.body).to include("更新する")
    end

    it "一般社員には、更新フォームが表示されない" do
      sign_in employee
      get ticket_path(ticket)
      expect(response.body).not_to include("更新する")
    end

    it "ステータスが日本語で表示される" do
      sign_in employee
      get ticket_path(ticket)
      expect(response.body).to include("受付済み")
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

    it "内容に応じて、カテゴリが自動で設定される" do
      account = create(:category, name: "アカウント")
      create(:category_rule, category: account, keyword: "パスワード")

      post tickets_path, params: { ticket: { title: "ログインできない", body: "パスワードを忘れました" } }

      expect(Ticket.last.category).to eq account
    end
  end

  describe "PATCH /tickets/:id" do
    let(:ticket) { create(:ticket, requester: employee) }
    let(:category) { create(:category) }

    it "未ログインなら、ログイン画面へ移動する" do
      patch ticket_path(ticket), params: { ticket: { status: "in_progress" } }
      expect(response).to redirect_to(new_session_path)
    end

    it "IT担当者は、担当者を割り当てて対応中にできる" do
      sign_in staff
      patch ticket_path(ticket), params: { ticket: { assignee_id: staff.id, status: "in_progress" } }

      expect(response).to redirect_to(ticket_path(ticket))
      ticket.reload
      expect(ticket.status).to eq "in_progress"
      expect(ticket.assignee).to eq staff
    end

    it "IT担当者は、カテゴリを設定できる" do
      sign_in staff
      patch ticket_path(ticket), params: { ticket: { category_id: category.id } }
      expect(ticket.reload.category).to eq category
    end

    it "依頼者本人でも、一般社員は更新できない(403)" do
      sign_in employee
      patch ticket_path(ticket), params: { ticket: { status: "closed" } }

      expect(response).to have_http_status(:forbidden)
      expect(ticket.reload.status).to eq "received"
    end

    it "無関係の一般社員には、存在しない扱い(404)になる" do
      sign_in other_employee
      patch ticket_path(ticket), params: { ticket: { status: "in_progress" } }
      expect(response).to have_http_status(:not_found)
    end

    it "許可されないステータス遷移は、422を返して更新されない" do
      sign_in staff
      patch ticket_path(ticket), params: { ticket: { assignee_id: staff.id, status: "resolved" } }

      expect(response).to have_http_status(422)
      expect(ticket.reload.status).to eq "received"
    end

    it "担当者に一般社員は指定できない" do
      sign_in staff
      patch ticket_path(ticket), params: { ticket: { assignee_id: other_employee.id } }

      expect(response).to have_http_status(422)
      expect(ticket.reload.assignee).to be_nil
    end
  end
end
