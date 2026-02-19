module Kanban
  class MoveConversationService
    pattr_initialize [:conversation!, :kanban_column!]

    def perform
      validate_same_account!
      validate_same_inbox!
      validate_not_archived!

      Conversation.transaction do
        conversation.kanban_column = kanban_column
        apply_status_from_column_type
        conversation.save!
      end

      conversation
    end

    private

    def validate_same_account!
      return if conversation.account_id == kanban_column.board.account_id

      raise ActiveRecord::RecordNotFound
    end

    def validate_not_archived!
      return unless kanban_column.archived?

      raise ActiveRecord::RecordInvalid.new(kanban_column)
    end

    def validate_same_inbox!
      return if conversation.inbox_id == kanban_column.board.inbox_id

      raise ActiveRecord::RecordNotFound
    end

    def apply_status_from_column_type
      status = kanban_column.conversation_status
      return if status.nil?

      conversation.status = status
    end
  end
end
