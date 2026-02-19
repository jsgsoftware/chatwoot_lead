json.id @board.id
json.account_id @board.account_id
json.inbox_id @board.inbox_id
json.name @board.name

json.columns @columns do |column|
  json.partial! 'api/v1/accounts/kanban_columns/column', column: column
end
