<script setup>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { onMounted } from 'vue';

const toggleSupportWidgetVisibility = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggleBubbleVisibility('show');
  }
};

const setupListenerForWidgetEvent = () => {
  window.addEventListener('chatwoot:on-message', () => {
    toggleSupportWidgetVisibility();
  });
};

onMounted(() => {
  toggleSupportWidgetVisibility();
  setupListenerForWidgetEvent();
});
</script>

<template>
  <div class="items-center bg-n-slate-2 flex justify-center h-full w-full">
    <EmptyState
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE')"
    >
      <div class="flex justify-center mt-6">
        <a
          href="https://api.whatsapp.com/send?phone=50760634535&text=Hola%20quiero%20obtener%20la%20subscripcion%20de%20leadflowai"
          target="_blank"
          rel="noopener noreferrer"
          class="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded shadow"
        >
          Contactar por WhatsApp
        </a>
      </div>
    </EmptyState>
  </div>
</template>
