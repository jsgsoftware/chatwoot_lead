/* global axios */
import ApiClient from './ApiClient';

class KanbanBoardsApi extends ApiClient {
  constructor() {
    super('kanban_boards', { accountScoped: true });
  }

  // NOTE: In this implementation, we use `:id` as `inbox_id`.
  showByInboxId(inboxId) {
    return axios.get(`${this.url}/${inboxId}`);
  }
}

export default new KanbanBoardsApi();
