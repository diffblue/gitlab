<script>
import AiGenieChatMessage from 'ee/ai/components/ai_genie_chat_message.vue';
import { i18n } from '../constants';

export default {
  name: 'AiGenieChatConversation',
  components: {
    AiGenieChatMessage,
  },
  props: {
    messages: {
      type: Array,
      required: false,
      default: () => [],
    },
    showDelimiter: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  methods: {
    isLastMessage(index) {
      return index === this.messages.length - 1;
    },
    getPromptLocation(index) {
      // TODO: do we really need this? And if yes, can it be converted to play with is-last-message?
      return index ? 'after_content' : 'before_content';
    },
  },
  i18n,
};
</script>
<template>
  <div>
    <template v-if="showDelimiter">
      <div
        class="gl-my-5 gl-display-flex gl-align-items-center gl-text-gray-500 gl-gap-4 gl-mb-5 gl-mt-n5"
        data-testid="conversation-delimiter"
      >
        <hr class="gl-my-5 gl-flex-grow-1" />
        <span>{{ $options.i18n.GENIE_CHAT_NEW_CHAT }}</span>
        <hr class="gl-my-5 gl-flex-grow-1" />
      </div>
    </template>
    <ai-genie-chat-message
      v-for="(msg, index) in messages"
      :key="`${msg.role}-${index}`"
      :message="msg"
      :prompt-location="getPromptLocation(index)"
      :is-last-message="isLastMessage(index)"
    />
  </div>
</template>
