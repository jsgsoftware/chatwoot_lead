class Api::V1::Accounts::KanbanBoardsController < Api::V1::Accounts::BaseController
  before_action :fetch_board

  def show
    @columns = @board.active_columns.includes(:board)
  end

  private

  def fetch_board
    inbox = Current.account.inboxes.find(params[:id])
    authorize inbox, :show?

    @board = Current.account.kanban_boards.find_or_create_by!(inbox: inbox) do |board|
      board.name = inbox.name
    end
  end
end

Api::V1::Accounts::KanbanBoardsController.prepend_mod_with('Api::V1::Accounts::KanbanBoardsController')
