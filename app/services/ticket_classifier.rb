class TicketClassifier
  DEFAULT_CATEGORY_NAME = "その他".freeze

  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @text = text.to_s.downcase
  end

  def call
    matched_rules = CategoryRule.includes(:category).order(:id).select do |rule|
      @text.include?(rule.keyword.downcase)
    end
    return default_category if matched_rules.empty?

    best = matched_rules.group_by(&:category_id).max_by do |_category_id, rules|
      [ rules.size, -rules.first.id ]
    end
    best.last.first.category
  end

  private

  def default_category
    Category.find_by(name: DEFAULT_CATEGORY_NAME)
  end
end
