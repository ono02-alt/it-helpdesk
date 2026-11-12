%w[アカウント PC・端末 ネットワーク ソフトウェア その他].each do |name|
  Category.find_or_create_by!(name: name)
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
