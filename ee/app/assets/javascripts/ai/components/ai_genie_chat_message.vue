<script>
import { renderMarkdown } from '~/notes/utils';
import { getMarkdown } from '~/rest_api';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { GENIE_CHAT_MODEL_ROLES } from '../constants';

export default {
  name: 'AiGenieChatMessage',
  directives: {
    SafeHtml,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
    promptLocation: {
      type: String,
      required: false,
      default: 'after_content',
    },
  },
  data() {
    return {
      messageContent: renderMarkdown(this.message.content || this.message.errors[0]),
    };
  },
  mounted() {
    this.hydrateContentWithGFM();
  },
  methods: {
    isAssistantMessage(message) {
      return message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.assistant;
    },
    isUserMessage(message) {
      return message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.user;
    },
    async hydrateContentWithGFM() {
      const textToConvert = this.message.content || this.message.errors[0];
      if (textToConvert) {
        this.messageContent = (await getMarkdown({ text: textToConvert, gfm: true })).data.html;
        await this.$nextTick();
        renderGFM(this.$refs.content);
      }
    },
  },
};
</script>
<template>
  <div
    class="gl-py-3 gl-mb-4 gl-px-4 gl-rounded-lg gl-line-height-20 gl-word-break-word ai-genie-chat-message"
    :class="{
      'gl-ml-auto gl-bg-blue-100 gl-text-blue-900 gl-rounded-bottom-right-none': isUserMessage(
        message,
      ),
      'gl-rounded-bottom-left-none gl-text-gray-900 gl-bg-white gl-border-1 gl-border-solid gl-border-gray-50': isAssistantMessage(
        message,
      ),
    }"
  >
    <div ref="content" v-safe-html="messageContent"></div>
    <slot
      v-if="isAssistantMessage(message)"
      name="feedback"
      :prompt-location="promptLocation"
      :message="message"
    ></slot>
  </div>
</template>
