<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Draggable from 'vuedraggable';
import wootConstants from 'dashboard/constants/globals';
import { useAlert } from 'dashboard/composables';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import KanbanBoardsAPI from 'dashboard/api/kanbanBoards';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  inboxId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { getPlainText } = useMessageFormatter();

const STATUS_TYPES = wootConstants.STATUS_TYPE;

const columns = ref([]);
const isBoardLoading = ref(false);

const allConversations = useMapGetter('getAllConversations');
const isFetchingConversations = useMapGetter('getChatListLoadingStatus');

const backlogColumnId = computed(() => {
  const backlog = columns.value.find(c => c.column_type === 'backlog');
  return backlog?.id;
});

const isKnownColumnId = computed(() => {
  const ids = new Set(columns.value.map(c => c.id));
  return id => ids.has(id);
});

const conversationsForInbox = computed(() => {
  const targetInboxId = Number(props.inboxId);
  return allConversations.value.filter(conv => conv.inbox_id === targetInboxId);
});

const getConversationColumnId = conversation => {
  const candidate = conversation.kanban_column_id;
  if (candidate && isKnownColumnId.value(candidate)) return candidate;
  return backlogColumnId.value;
};

const columnLists = ref({});

const rebuildLists = () => {
  const byColumnId = {};
  columns.value.forEach(column => {
    byColumnId[column.id] = conversationsForInbox.value.filter(
      conv => getConversationColumnId(conv) === column.id
    );
  });
  columnLists.value = byColumnId;
};

watch([columns, conversationsForInbox], rebuildLists, { immediate: true });

const hasConversations = computed(() => {
  return conversationsForInbox.value.length > 0;
});

const iconForColumnType = columnType => {
  if (columnType === 'backlog') return 'i-lucide-inbox';
  if (columnType === 'waiting') return 'i-lucide-clock';
  if (columnType === 'done') return 'i-lucide-check-circle';
  return 'i-lucide-circle-dot';
};

const fetchBoard = async () => {
  isBoardLoading.value = true;
  try {
    const response = await KanbanBoardsAPI.showByInboxId(props.inboxId);
    columns.value = response.data.columns || [];
  } finally {
    isBoardLoading.value = false;
  }
};

const resetAndFetchConversations = async () => {
  store.dispatch('conversationPage/reset');
  store.dispatch('emptyAllConversations');
  store.dispatch('setChatListFilters', {
    inboxId: Number(props.inboxId),
    status: STATUS_TYPES.ALL,
    assigneeType: wootConstants.ASSIGNEE_TYPE.ALL,
    page: 1,
  });
  await store.dispatch('fetchAllConversations');
};

const init = async () => {
  await fetchBoard();
  await resetAndFetchConversations();
};

onMounted(init);

watch(
  () => props.inboxId,
  async () => {
    await init();
  }
);

const getContactName = conversation => {
  return (
    conversation?.meta?.sender?.name ||
    conversation?.meta?.sender?.availableName ||
    'Unknown'
  );
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

const openConversation = conversation => {
  const accountId = router.currentRoute.value.params.accountId;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId,
      conversation_id: conversation.id,
    },
  });
};

const moveInProgress = ref(new Set());

const handleDrop = async (event, targetColumn) => {
  const { added } = event;
  if (!added?.element) return;

  const conversation = added.element;
  const key = `${conversation.id}:${targetColumn.id}`;
  if (moveInProgress.value.has(key)) return;
  moveInProgress.value.add(key);

  try {
    await store.dispatch('moveKanban', {
      conversationId: conversation.id,
      kanbanColumnId: targetColumn.id,
    });
    useAlert(t('KANBAN.STATUS_CHANGED'));
  } catch {
    // optimistic update is reverted in the store action
  } finally {
    moveInProgress.value.delete(key);
  }
};

const hasEndReached = computed(() => {
  const getter = store.getters['conversationPage/getHasEndReached'];
  return getter ? getter(wootConstants.ASSIGNEE_TYPE.ALL) : false;
});

const loadNextPage = async () => {
  if (isFetchingConversations.value || hasEndReached.value) return;

  const pageGetter = store.getters['conversationPage/getCurrentPageFilter'];
  const currentPage = pageGetter
    ? pageGetter(wootConstants.ASSIGNEE_TYPE.ALL)
    : 1;

  store.dispatch('updateChatListFilters', { page: currentPage + 1 });
  await store.dispatch('fetchAllConversations');
};

const onColumnScroll = async event => {
  const el = event.target;
  if (!el) return;

  const nearBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - 32;
  if (!nearBottom) return;

  await loadNextPage();
};
</script>

<template>
  <div class="flex flex-col h-screen bg-n-background">
    <div
      class="flex items-center justify-between px-6 py-4 border-b border-n-slate-3 flex-shrink-0"
    >
      <h1 class="text-2xl font-semibold text-n-slate-12">
        {{ t('KANBAN.HEADER_TITLE') }}
      </h1>
      <p class="text-sm text-n-slate-11">
        {{ t('KANBAN.DRAG_MESSAGE') }}
      </p>
    </div>

    <div
      v-if="isBoardLoading"
      class="flex-1 flex items-center justify-center p-8 text-n-slate-11"
    >
      {{ t('LOADING') }}
    </div>

    <div v-else-if="!hasConversations" class="flex-1 flex items-center justify-center p-8">
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

    <div v-else class="flex flex-1 gap-4 p-6 overflow-x-auto">
      <div
        v-for="column in columns"
        :key="column.id"
        class="flex flex-col flex-shrink-0 w-80 bg-n-solid-3 rounded-lg"
      >
        <div class="flex items-center justify-between px-4 py-3 border-b border-n-slate-3">
          <div class="flex items-center gap-2">
            <Icon
              :icon="iconForColumnType(column.column_type)"
              class="text-n-slate-11 size-4"
            />
            <h3 class="font-semibold text-n-slate-12">
              {{ column.name }}
            </h3>
          </div>
          <span class="px-2 py-1 text-xs font-medium rounded-full bg-n-alpha-2 text-n-slate-11">
            {{ (columnLists[column.id] || []).length }}
          </span>
        </div>

        <div
          class="flex flex-col flex-1 gap-2 p-3 overflow-y-auto"
          @scroll="onColumnScroll"
        >
          <Draggable
            :list="columnLists[column.id]"
            :group="{ name: 'kanban' }"
            item-key="id"
            :sort="false"
            @change="event => handleDrop(event, column)"
          >
            <template #item="{ element: conversation }">
              <div
                class="flex flex-col gap-2 p-3 rounded-lg cursor-move bg-n-background"
              >
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
                  <button
                    class="ml-2 p-1 rounded hover:bg-n-alpha-2 focus:outline-none"
                    @click.stop="openConversation(conversation)"
                    :title="t('KANBAN.VIEW_CONVERSATION')"
                  >
                    <Icon icon="i-lucide-eye" class="size-5 text-n-slate-11" />
                  </button>
                </div>

                <p class="text-sm line-clamp-2 text-n-slate-11">
                  {{ getLastMessageContent(conversation) }}
                </p>

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
            </template>
          </Draggable>

          <div
            v-if="(columnLists[column.id] || []).length === 0"
            class="flex items-center justify-center h-32 text-sm text-n-slate-11"
          >
            Drop conversations here
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
