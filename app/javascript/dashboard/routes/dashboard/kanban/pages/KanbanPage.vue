<script setup>
import { getUserRole } from 'dashboard/helper/permissionsHelper';
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import KanbanView from '../components/KanbanView.vue';

const router = useRouter();

const showKanban = import.meta.env.VITE_SHOW_KANBAN === 'true';

const currentUser = useMapGetter('getCurrentUser');
const inboxes = useMapGetter('inboxes/getInboxes');

const accountId = computed(() => router.currentRoute.value.params.accountId);

const isSuperAdmin = computed(
  () => currentUser.value?.type === 'SuperAdmin'
);

const isAdministrator = computed(() => {
  const role = getUserRole(currentUser.value, accountId.value);
  return role === 'administrator';
});

const canShowKanban = computed(() => {
  if (isSuperAdmin.value) return true;
  if (showKanban) return isAdministrator.value;
  return false;
});

const activeInboxId = computed(() => {
  const inboxIdFromQuery = Number(router.currentRoute.value.query.inbox_id);
  if (inboxIdFromQuery) return inboxIdFromQuery;
  return inboxes.value?.[0]?.id;
});
</script>

<template>
  <KanbanView v-if="canShowKanban && activeInboxId" :inbox-id="activeInboxId" />
  <div v-else class="flex items-center justify-center h-screen" />
</template>
