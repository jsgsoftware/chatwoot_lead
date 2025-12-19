import { frontendURL } from '../../../helper/URLHelper';
import KanbanPage from './pages/KanbanPage.vue';

const meta = {
  permissions: ['administrator', 'agent'],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/kanban'),
      name: 'kanban_index',
      component: KanbanPage,
      meta,
    },
  ],
};
