class CreateKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_columns do |t|
      t.references :board, null: false, foreign_key: { to_table: :kanban_boards }, index: true
      t.string :name, null: false
      t.integer :position, null: false
      t.integer :column_type, null: false
      t.integer :wip_limit
      t.boolean :archived, null: false, default: false

      t.timestamps
    end

    add_index :kanban_columns, %i[board_id position]
    add_index :kanban_columns, %i[board_id column_type]
  end
end
