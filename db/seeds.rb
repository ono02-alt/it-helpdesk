categories = %w[アカウント PC・端末 ネットワーク ソフトウェア その他].index_with do |name|
  Category.find_or_create_by!(name: name)
end

{
  "アカウント" => %w[パスワード ログイン ロック アカウント 権限],
  "PC・端末" => %w[PC パソコン 画面 起動 キーボード マウス],
  "ネットワーク" => %w[Wi-Fi ネット VPN 接続 遅い],
  "ソフトウェア" => %w[インストール Excel Outlook アプリ 更新]
}.each do |name, keywords|
  keywords.each do |keyword|
    CategoryRule.find_or_create_by!(category: categories[name], keyword: keyword)
  end
end

if Rails.env.development?
  [
    { name: "山田 太郎", email_address: "employee@example.com", role: :employee },
    { name: "佐藤 花子", email_address: "staff@example.com", role: :it_staff },
    { name: "鈴木 一郎", email_address: "admin@example.com", role: :admin }
  ].each do |attrs|
    User.find_or_create_by!(email_address: attrs[:email_address]) do |user|
      user.name = attrs[:name]
      user.role = attrs[:role]
      user.password = "password123"
    end
  end
end
