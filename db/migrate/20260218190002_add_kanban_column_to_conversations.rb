class AddKanbanColumnToConversations < ActiveRecord::Migration[7.1]
  def change
    add_reference :conversations, :kanban_column, foreign_key: true, index: true
  end
end
