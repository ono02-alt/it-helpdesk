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

  before_save :update_resolved_at, if: :status_changed?

  private

  def assignee_must_be_staff
    return if assignee.nil? || assignee.it_staff? || assignee.admin?

    errors.add(:assignee, "はIT担当者か管理者にしてください")
  end

  def status_transition_must_be_allowed
    return unless status_changed?

    unless ALLOWED_TRANSITIONS.fetch(status_was, []).include?(status)
      errors.add(:status, "は#{status_was}から#{status}へ変更できません")
    end
  end

  def update_resolved_at
    if resolved?
      self.resolved_at = Time.current
    elsif in_progress?
      self.resolved_at = nil
    end
  end
end
