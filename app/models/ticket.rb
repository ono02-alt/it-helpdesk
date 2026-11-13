class Ticket < ApplicationRecord
  ALLOWED_TRANSITIONS = {
    "received" => %w[in_progress],
    "in_progress" => %w[resolved],
    "resolved" => %w[in_progress closed],
    "closed" => []
  }.freeze

  belongs_to :requester, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :category, optional: true

  enum :status, { received: 0, in_progress: 1, resolved: 2, closed: 3 }, validate: true
  enum :priority, { low: 0, normal: 1, high: 2 }, validate: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true
  validates :assignee, presence: true, unless: :received?
  validate :assignee_must_be_staff
  validate :status_transition_must_be_allowed, on: :update

  before_validation :classify_automatically, on: :create
  before_save :update_resolved_at, if: :status_changed?

  def self.status_options
    statuses.keys.map { |key| [ human_attribute_name("statuses.#{key}"), key ] }
  end

  def self.priority_options
    priorities.keys.map { |key| [ human_attribute_name("priorities.#{key}"), key ] }
  end

  def status_text
    self.class.human_attribute_name("statuses.#{status}")
  end

  def priority_text
    self.class.human_attribute_name("priorities.#{priority}")
  end

  private

  def assignee_must_be_staff
    return if assignee.nil? || assignee.it_staff? || assignee.admin?

    errors.add(:assignee, "はIT担当者か管理者にしてください")
  end

  def status_transition_must_be_allowed
    return unless status_changed?
    return if ALLOWED_TRANSITIONS.fetch(status_was, []).include?(status)

    from = self.class.human_attribute_name("statuses.#{status_was}")
    to = self.class.human_attribute_name("statuses.#{status}")
    errors.add(:status, "は「#{from}」から「#{to}」へ変更できません")
  end

  def update_resolved_at
    if resolved?
      self.resolved_at = Time.current
    elsif in_progress?
      self.resolved_at = nil
    end
  end

  def classify_automatically
    return if category.present?

    self.category = TicketClassifier.call("#{title} #{body}")
  end
end
