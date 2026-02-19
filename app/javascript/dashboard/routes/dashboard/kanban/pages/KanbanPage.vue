<script setup>
import { getUserRole } from 'dashboard/helper/permissionsHelper';
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import wootConstants from 'dashboard/constants/globals';
import { useAlert } from 'dashboard/composables';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useRouter } from 'vue-router';


const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { getPlainText } = useMessageFormatter();

// Obtener variable de entorno (Vite expone import.meta.env)
const showKanban = import.meta.env.VITE_SHOW_KANBAN === 'true';

// Obtener usuario y rol actual
const currentUser = store.getters['getCurrentUser'];
const accountId = router.currentRoute.value.params.accountId;
const userRole = getUserRole(currentUser, accountId);

// Lógica de visibilidad
const canShowKanban = computed(() => {
  if (showKanban) {
    return userRole === 'administrator' || userRole === 'superadmin';
  }
  return userRole === 'superadmin';
});

const STATUS_TYPES = wootConstants.STATUS_TYPE;

const columns = [
  { key: STATUS_TYPES.OPEN, label: t('KANBAN.COLUMNS.OPEN'), icon: 'i-lucide-circle-dot' },
  { key: STATUS_TYPES.PENDING, label: t('KANBAN.COLUMNS.PENDING'), icon: 'i-lucide-clock' },
  { key: STATUS_TYPES.SNOOZED, label: t('KANBAN.COLUMNS.SNOOZED'), icon: 'i-lucide-alarm-clock' },
  { key: STATUS_TYPES.RESOLVED, label: t('KANBAN.COLUMNS.RESOLVED'), icon: 'i-lucide-check-circle' },
];

const draggedConversation = ref(null);
const draggedFromColumn = ref(null);

const allConversations = useMapGetter('getAllConversations');

const getConversationsByStatus = status => {
  return computed(() => {
    return allConversations.value.filter(conv => conv.status === status);
  });
};

const conversationsByColumn = computed(() => {
  return columns.map(col => ({
    ...col,
    conversations: getConversationsByStatus(col.key).value,
  }));
});

const hasConversations = computed(() => {
  return allConversations.value.length > 0;
});

onMounted(() => {
  store.dispatch('fetchAllConversations');
});

const getContactName = conversation => {
  return conversation?.meta?.sender?.name || conversation?.meta?.sender?.availableName || 'Unknown';
};

const getContactThumbnail = conversation => {
  return conversation?.meta?.sender?.thumbnail || '';
};

const getLastMessageContent = conversation => {
  const lastMessage = getLastMessage(conversation);
  return getPlainText(lastMessage?.content || t('CHAT_LIST.NO_CONTENT'));
};

const getFormattedTimestamp = conversation => {
  const timestamp = conversation?.last_activity_at;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
};

const getAssigneeName = conversation => {
  return conversation?.meta?.assignee?.name || '';
};

const getInboxName = conversation => {
  const inbox = store.getters['inboxes/getInbox'](conversation?.inbox_id);
  return inbox?.name || '';
};

const onDragStart = (event, conversation, columnKey) => {
  draggedConversation.value = conversation;
  draggedFromColumn.value = columnKey;
  event.dataTransfer.effectAllowed = 'move';
};

const onDragOver = event => {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
};

const onDrop = async (event, targetStatus) => {
  event.preventDefault();
  
  if (!draggedConversation.value || draggedFromColumn.value === targetStatus) {
    draggedConversation.value = null;
    draggedFromColumn.value = null;
    return;
  }

  try {
    await store.dispatch('toggleStatus', {
      conversationId: draggedConversation.value.id,
      status: targetStatus,
    });
    
    useAlert(t('KANBAN.STATUS_CHANGED'));
  } catch (error) {
    console.error('Error updating conversation status:', error);
  } finally {
    draggedConversation.value = null;
    draggedFromColumn.value = null;
  }
};

const onDragEnd = () => {
  draggedConversation.value = null;
  draggedFromColumn.value = null;
};

function openConversation(conversation) {
  // Obtener el accountId desde la ruta actual
  const accountId = router.currentRoute.value.params.accountId;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId,
      conversation_id: conversation.id,
    },
  });
}
</script>

<template>
  <div v-if="canShowKanban" class="flex flex-col h-screen bg-n-background">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-slate-3 flex-shrink-0">
      <h1 class="text-2xl font-semibold text-n-slate-12">
        {{ t('KANBAN.HEADER_TITLE') }}
      </h1>
      <p class="text-sm text-n-slate-11">
        {{ t('KANBAN.DRAG_MESSAGE') }}
      </p>
    </div>

    <!-- Empty State -->
    <div v-if="!hasConversations" class="flex-1 flex items-center justify-center p-8">
      <div class="flex flex-col items-center gap-4 max-w-md">
        <div class="flex items-center justify-center rounded-full bg-n-alpha-2 size-16">
          <Icon icon="i-lucide-inbox" class="text-n-slate-11 size-8" />
        </div>
        <div class="flex flex-col items-center gap-2 text-center">
          <h2 class="text-2xl font-semibold text-n-slate-12">
            {{ t('KANBAN.EMPTY_STATE_TITLE') }}
          </h2>
          <p class="text-n-slate-11">
            {{ t('KANBAN.EMPTY_STATE_MESSAGE') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Kanban Board -->
    <div v-else class="flex flex-1 gap-4 p-6 overflow-x-auto">
      <div
        v-for="column in conversationsByColumn"
        :key="column.key"
        class="flex flex-col flex-shrink-0 w-80 bg-n-solid-3 rounded-lg"
        @dragover="onDragOver"
        @drop="onDrop($event, column.key)"
      >
        <!-- Column Header -->
        <div class="flex items-center justify-between px-4 py-3 border-b border-n-slate-3">
          <div class="flex items-center gap-2">
            <Icon :icon="column.icon" class="text-n-slate-11 size-4" />
            <h3 class="font-semibold text-n-slate-12">
              {{ column.label }}
            </h3>
          </div>
          <span class="px-2 py-1 text-xs font-medium rounded-full bg-n-alpha-2 text-n-slate-11">
            {{ column.conversations.length }}
          </span>
        </div>

        <!-- Conversations List -->
        <div class="flex flex-col flex-1 gap-2 p-3 overflow-y-auto">
          <div
            v-for="conversation in column.conversations"
            :key="conversation.id"
            class="flex flex-col gap-2 p-3 transition-all duration-200 rounded-lg cursor-move bg-n-background hover:shadow-md hover:scale-[1.02]"
            draggable="true"
            @dragstart="onDragStart($event, conversation, column)"
            @dragend="onDragEnd"
            :class="{ 'dragging': draggingConversationId === conversation.id }"
          >
            <!-- Contact Info -->
            <div class="flex items-center gap-2">
              <Avatar
                :name="getContactName(conversation)"
                :src="getContactThumbnail(conversation)"
                :size="32"
                rounded-full
              />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium truncate text-n-slate-12">
                  {{ getContactName(conversation) }}
                </p>
                <p class="text-xs truncate text-n-slate-11">
                  {{ getInboxName(conversation) }}
                </p>
              </div>
              <!-- Eye Icon Button -->
              <button
                class="ml-2 p-1 rounded hover:bg-n-alpha-2 focus:outline-none"
                @click.stop="openConversation(conversation)"
                :title="t('KANBAN.VIEW_CONVERSATION')"
              >
                <Icon icon="i-lucide-eye" class="size-5 text-n-slate-11" />
              </button>
            </div>

            <!-- Last Message -->
            <p class="text-sm line-clamp-2 text-n-slate-11">
              {{ getLastMessageContent(conversation) }}
            </p>

            <!-- Footer -->
            <div class="flex items-center justify-between pt-2 border-t border-n-slate-3">
              <span
                v-if="getAssigneeName(conversation)"
                class="flex items-center gap-1 text-xs text-n-slate-11"
              >
                <Icon icon="i-lucide-user" class="size-3" />
                {{ getAssigneeName(conversation) }}
              </span>
              <span class="text-xs text-n-slate-11">
                {{ getFormattedTimestamp(conversation) }}
              </span>
            </div>
          </div>

          <!-- Empty Column State -->
          <div
            v-if="column.conversations.length === 0"
            class="flex items-center justify-center h-32 text-sm text-n-slate-11"
          >
            Drop conversations here
          </div>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="flex items-center justify-center h-screen">
    <!-- No mostrar nada o mensaje opcional -->
  </div>
</template>
