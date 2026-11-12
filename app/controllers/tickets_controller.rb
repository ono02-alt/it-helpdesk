class TicketsController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @tickets = policy_scope(Ticket)
      .includes(:requester, :assignee, :category)
      .order(created_at: :desc)
  end

  def show
    @ticket = policy_scope(Ticket).find(params[:id])
    authorize @ticket
  end

  def new
    @ticket = Ticket.new
    authorize @ticket
  end

  def create
    @ticket = Ticket.new(ticket_params.merge(requester: Current.user))
    authorize @ticket

    if @ticket.save
      redirect_to @ticket, notice: "問い合わせを登録しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def ticket_params
    params.expect(ticket: [ :title, :body, :priority ])
  end
end