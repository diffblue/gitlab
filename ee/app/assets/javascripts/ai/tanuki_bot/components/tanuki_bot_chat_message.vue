<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { __, s__, n__ } from '~/locale';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { MESSAGE_TYPES, SOURCE_TYPES, TANUKI_BOT_FEEDBACK_ISSUE_URL } from '../constants';

export default {
  name: 'TanukiBotChatMessage',
  i18n: {
    giveFeedback: s__('TanukiBot|Give feedback'),
    source: __('Source'),
  },
  components: {
    GlLink,
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isUserMessage() {
      return this.message.role === MESSAGE_TYPES.USER;
    },
    isTanukiMessage() {
      return this.message.role === MESSAGE_TYPES.TANUKI;
    },
    hasSources() {
      return this.message.extras?.sources?.length > 0;
    },
    sourceLabel() {
      return n__('TanukiBot|Source', 'TanukiBot|Sources', this.message.extras?.sources?.length);
    },
  },
  mounted() {
    this.$refs.message.scrollIntoView({ behavior: 'smooth' });
  },
  methods: {
    getSourceIcon(sourceType) {
      const currentSourceType = Object.values(SOURCE_TYPES).find(
        ({ value }) => value === sourceType,
      );

      return currentSourceType?.icon;
    },
    getSourceTitle({ title, source_type: sourceType, stage, group, date, author }) {
      if (title) {
        return title;
      }

      if (sourceType === SOURCE_TYPES.DOC.value) {
        if (stage && group) {
          return `${stage} / ${group}`;
        }
      }

      if (sourceType === SOURCE_TYPES.BLOG.value) {
        if (date && author) {
          return `${date} / ${author}`;
        }
      }

      return this.$options.i18n.source;
    },
    renderMarkdown,
  },
  TANUKI_BOT_FEEDBACK_ISSUE_URL,
};
</script>

<template>
  <div
    ref="message"
    data-testid="tanuki-bot-chat-message"
    class="gl-py-3 gl-px-4 gl-mb-6 gl-rounded-lg"
    :class="{
      'gl-ml-auto gl-bg-blue-100 gl-text-blue-900 gl-rounded-bottom-right-none': isUserMessage,
      'tanuki-bot-message gl-text-gray-900 gl-rounded-bottom-left-none': isTanukiMessage,
    }"
  >
    <div
      v-if="isTanukiMessage"
      v-safe-html="renderMarkdown(message.content)"
      class="tanuki-bot-chat-message-markdown"
    ></div>
    <p v-if="isUserMessage" class="gl-mb-0">{{ message.content }}</p>
    <div v-if="isTanukiMessage" class="gl-display-flex gl-align-items-flex-end gl-mt-4">
      <div
        v-if="hasSources"
        class="gl-mr-3 gl-text-gray-600"
        data-testid="tanuki-bot-chat-message-sources"
      >
        <span>{{ sourceLabel }}</span>
        <ul class="gl-pl-5 gl-my-0">
          <li v-for="(source, index) in message.extras.sources" :key="index">
            <gl-icon v-if="source.source_type" :name="getSourceIcon(source.source_type)" />
            <gl-link :href="source.source_url">{{ getSourceTitle(source) }}</gl-link>
          </li>
        </ul>
      </div>
      <gl-link
        class="gl-ml-auto gl-white-space-nowrap"
        :href="$options.TANUKI_BOT_FEEDBACK_ISSUE_URL"
        target="_blank"
        ><gl-icon name="comment" /> {{ $options.i18n.giveFeedback }}</gl-link
      >
    </div>
  </div>
</template>
