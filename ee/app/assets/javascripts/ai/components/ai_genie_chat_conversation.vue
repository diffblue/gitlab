<script>
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { GENIE_CHAT_MODEL_ROLES, i18n } from '../constants';

export default {
  name: 'AiGenieChatConversation',
  directives: {
    SafeHtml,
  },
  props: {
    messages: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
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
    isAssistantMessage(message) {
      return message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.assistant;
    },
    isUserMessage(message) {
      return message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.user;
    },
    getMessageContent(message) {
      return renderMarkdown(message.content || message.errors[0]);
    },
    getPromptLocation(index) {
      return index ? 'after_content' : 'before_content';
    },
    renderMarkdown,
  },
  i18n,
};
</script>
<template>
  <div class="gl-my-5">
    <template v-if="showDelimiter">
      <div
        class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-gap-4 gl-mb-5 gl-mt-n5"
        data-testid="conversation-delimiter"
      >
        <hr class="gl-my-5 gl-flex-grow-1" />
        <span>{{ $options.i18n.GENIE_CHAT_NEW_CHAT }}</span>
        <hr class="gl-my-5 gl-flex-grow-1" />
      </div>
    </template>

    <div
      v-for="(message, index) in messages"
      :key="`${message.role}-${index}`"
      :ref="isLastMessage(index) ? 'lastMessage' : undefined"
      class="gl-py-3 gl-px-4 gl-mb-4 gl-rounded-lg gl-line-height-20 ai-genie-chat-message"
      :class="{
        'gl-ml-auto gl-bg-blue-100 gl-text-blue-900 gl-rounded-bottom-right-none': isUserMessage(
          message,
        ),
        'gl-rounded-bottom-left-none gl-text-gray-900 gl-bg-gray-50': isAssistantMessage(message),
        'gl-mb-0!': isLastMessage(index) && !isLoading,
      }"
    >
      <div v-safe-html="getMessageContent(message)"></div>
      <slot
        v-if="isAssistantMessage(message)"
        name="feedback"
        :prompt-location="getPromptLocation(index)"
        :message="message"
      ></slot>
    </div>
  </div>
</template>
