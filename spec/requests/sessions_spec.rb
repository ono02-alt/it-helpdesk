require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "POST /session" do
    it "正しい情報でログインすると、一覧へ移動する" do
      post session_path, params: { email_address: user.email_address, password: "password123" }
      expect(response).to redirect_to(root_path)
    end

    it "パスワードが違うと、ログイン画面へ戻り、日本語のメッセージが出る" do
      post session_path, params: { email_address: user.email_address, password: "wrong-password" }
      expect(response).to redirect_to(new_session_path)

      follow_redirect!
      expect(response.body).to include("メールアドレスまたはパスワードが正しくありません")
    end
  end

  describe "DELETE /session" do
    it "ログアウトすると、ログイン画面へ移動し、一覧に入れなくなる" do
      sign_in user
      delete session_path
      expect(response).to redirect_to(new_session_path)

      get tickets_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
