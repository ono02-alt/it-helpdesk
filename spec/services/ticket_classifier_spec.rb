require "rails_helper"

RSpec.describe TicketClassifier do
  let!(:account) { create(:category, name: "アカウント") }
  let!(:software) { create(:category, name: "ソフトウェア") }
  let!(:pc) { create(:category, name: "PC・端末") }
  let!(:other) { create(:category, name: "その他") }

  before do
    create(:category_rule, category: account, keyword: "パスワード")
    create(:category_rule, category: account, keyword: "ログイン")
    create(:category_rule, category: software, keyword: "インストール")
    create(:category_rule, category: software, keyword: "アプリ")
    create(:category_rule, category: pc, keyword: "パソコン")
  end

  it "キーワードに一致したカテゴリを返す" do
    expect(described_class.call("パスワードを忘れました")).to eq account
  end

  it "一致したキーワードが多いカテゴリを優先する" do
    text = "パソコンにアプリをインストールしたら広告が出る"
    expect(described_class.call(text)).to eq software
  end

  it "一致数が同じなら、先に登録されたルールのカテゴリを返す" do
    text = "パスワードとインストールで困っている"
    expect(described_class.call(text)).to eq account
  end

  it "英字は大文字小文字を区別しない" do
    create(:category_rule, category: pc, keyword: "PC")
    expect(described_class.call("pcが起動しない")).to eq pc
  end

  it "どのキーワードにも一致しなければ、「その他」を返す" do
    expect(described_class.call("上司のメールアドレスがわからない")).to eq other
  end

  it "「その他」がなく、一致もなければ、nilを返す" do
    other.destroy
    expect(described_class.call("関係のない文章")).to be_nil
  end
end
