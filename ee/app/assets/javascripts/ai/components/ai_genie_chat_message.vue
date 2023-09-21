<script>
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import DocumentationSources from 'ee/ai/components/ai_genie_chat_message_sources.vue';
import { GENIE_CHAT_MODEL_ROLES } from '../constants';

const concatIndicesUntilEmpty = (arr) => {
  const start = arr.findIndex((el) => el);
  if (start === -1 || start !== 1) return ''; // If there are no non-empty elements

  const end = arr.slice(start).findIndex((el) => !el);
  return end > 0 ? arr.slice(start, end).join('') : arr.slice(start).join('');
};

export default {
  name: 'AiGenieChatMessage',
  messageChunks: [],
  components: {
    DocumentationSources,
    UserFeedback,
  },
  directives: {
    SafeHtml,
  },
  inject: ['trackingEventName'],
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
      messageContent: this.getContent(),
    };
  },
  computed: {
    isAssistantMessage() {
      return this.message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.assistant;
    },
    isUserMessage() {
      return this.message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.user;
    },
    sources() {
      return this.message.extras?.sources;
    },
  },
  watch: {
    message: {
      handler() {
        const { chunkId, content } = this.message;
        if (!chunkId) {
          this.$options.messageChunks = [];
          this.messageContent = this.getContent();
          renderGFM(this.$refs.content);
        } else {
          this.$options.messageChunks[chunkId] = content;
          this.messageContent = renderMarkdown(
            concatIndicesUntilEmpty(this.$options.messageChunks),
          );
        }
      },
      deep: true,
    },
  },
  mounted() {
    this.$options.messageChunks = [];
    if (this.message.chunkId) {
      this.$options.messageChunks[this.message.chunkId] = this.message.content;
    }
    renderGFM(this.$refs.content);
  },
  methods: {
    getContent() {
      return (
        this.message.contentHtml ||
        renderMarkdown(this.message.content || this.message.errors.join('; '))
      );
    },
  },
};
</script>
<template>
  <div
    class="gl-p-4 gl-mb-4 gl-rounded-lg gl-line-height-20 gl-word-break-word ai-genie-chat-message"
    :class="{
      'gl-ml-auto gl-bg-blue-100 gl-text-blue-900 gl-rounded-bottom-right-none': isUserMessage,
      'gl-rounded-bottom-left-none gl-text-gray-900 gl-bg-white gl-border-1 gl-border-solid gl-border-gray-50': isAssistantMessage,
    }"
  >
    <div ref="content" v-safe-html="messageContent"></div>

    <template v-if="isAssistantMessage">
      <documentation-sources v-if="sources" :sources="sources" />

      <div class="gl-display-flex gl-align-items-flex-end gl-mt-4">
        <user-feedback :event-name="trackingEventName" :prompt-location="promptLocation" />
      </div>
    </template>
  </div>
</template>
