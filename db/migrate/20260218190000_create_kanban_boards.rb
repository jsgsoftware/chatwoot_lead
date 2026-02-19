class CreateKanbanBoards < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_boards do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :kanban_boards, %i[account_id inbox_id], unique: true
  end
end
