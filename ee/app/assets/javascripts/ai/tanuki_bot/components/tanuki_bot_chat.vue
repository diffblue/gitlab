<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapState } from 'vuex';
import TanukiBotChatMessage from './tanuki_bot_chat_message.vue';

export default {
  name: 'TanukiBotChat',
  components: {
    TanukiBotChatMessage,
    GlLoadingIcon,
  },
  computed: {
    ...mapState(['loading', 'messages']),
  },
};
</script>

<template>
  <section class="gl-h-full">
    <transition-group
      tag="div"
      name="messages"
      class="gl-display-flex gl-flex-direction-column gl-justify-content-end gl-h-auto tanuki-bot-chat-chat-messages"
    >
      <tanuki-bot-chat-message v-for="message in messages" :key="message.id" :message="message" />
    </transition-group>
    <gl-loading-icon v-if="loading" class="gl-display-inline-flex gl-w-full gl-mb-5" />
  </section>
</template>
