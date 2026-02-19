class KanbanBoard < ApplicationRecord
  belongs_to :account
  belongs_to :inbox

  has_many :columns, class_name: 'KanbanColumn', foreign_key: :board_id, dependent: :destroy

  validates :name, presence: true
  validates :inbox_id, uniqueness: { scope: :account_id }

  after_create :ensure_required_columns!

  def active_columns
    columns.not_archived.order(:position)
  end

  def normalize_column_positions!
    columns.order(:position, :id).pluck(:id).each_with_index do |column_id, index|
      columns.where(id: column_id).update_all(position: index + 1)
    end
  end

  private

  def ensure_required_columns!
    return if columns.exists?

    columns.create!(
      name: 'Backlog',
      position: 1,
      column_type: :backlog
    )

    columns.create!(
      name: 'In progress',
      position: 2,
      column_type: :progress
    )

    columns.create!(
      name: 'Waiting',
      position: 3,
      column_type: :waiting
    )

    columns.create!(
      name: 'Done',
      position: 4,
      column_type: :done
    )
  end
end

KanbanBoard.prepend_mod_with('KanbanBoard')
