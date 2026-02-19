class Api::V1::Accounts::KanbanColumnsController < Api::V1::Accounts::BaseController
  before_action :fetch_column, only: [:update]

  def create
    board = Current.account.kanban_boards.find(kanban_column_params[:board_id])
    authorize board.inbox, :show?

    position = kanban_column_params[:position].presence || (board.columns.maximum(:position).to_i + 1)

    @column = board.columns.create!(
      name: kanban_column_params[:name],
      position: position,
      column_type: kanban_column_params[:column_type] || 'progress',
      wip_limit: kanban_column_params[:wip_limit]
    )

    board.normalize_column_positions!
  end

  def update
    @column.update!(kanban_column_update_params)
    @column.board.normalize_column_positions! if kanban_column_update_params.key?(:position)
  end

  private

  def fetch_column
    @column = KanbanColumn.joins(:board).where(kanban_boards: { account_id: Current.account.id }).find(params[:id])
    authorize @column.board.inbox, :show?
  end

  def kanban_column_params
    params.permit(:board_id, :name, :position, :column_type, :wip_limit)
  end

  def kanban_column_update_params
    params.permit(:name, :position, :wip_limit, :archived)
  end
end

Api::V1::Accounts::KanbanColumnsController.prepend_mod_with('Api::V1::Accounts::KanbanColumnsController')
