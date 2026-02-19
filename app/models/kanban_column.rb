class KanbanColumn < ApplicationRecord
  belongs_to :board, class_name: 'KanbanBoard'
  has_many :conversations, dependent: :nullify

  enum column_type: { backlog: 0, progress: 1, waiting: 2, done: 3 }

  scope :not_archived, -> { where(archived: false) }

  validates :name, presence: true
  validates :position, presence: true
  validates :column_type, presence: true

  validate :single_backlog_per_board, if: -> { backlog? && !archived? }
  validate :single_done_per_board, if: -> { done? && !archived? }
  validate :cannot_archive_required_columns

  def conversation_status
    return :resolved if done?
    return :open if backlog?
    return :pending if waiting?

    nil
  end

  private

  def single_backlog_per_board
    return if board.blank?

    if board.columns.not_archived.backlog.where.not(id: id).exists?
      errors.add(:column_type, 'backlog already exists for this board')
    end
  end

  def single_done_per_board
    return if board.blank?

    if board.columns.not_archived.done.where.not(id: id).exists?
      errors.add(:column_type, 'done already exists for this board')
    end
  end

  def cannot_archive_required_columns
    return unless archived_changed?(from: false, to: true)

    errors.add(:archived, 'cannot archive backlog column') if backlog?
    errors.add(:archived, 'cannot archive done column') if done?
  end
end

KanbanColumn.prepend_mod_with('KanbanColumn')
