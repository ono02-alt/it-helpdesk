class TicketPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.staff? || record.requester_id == user.id
  end

  def new?
    true
  end

  def create?
    true
  end

  def update?
    user.staff?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.staff? ? scope.all : scope.where(requester_id: user.id)
    end
  end
end