<script>
import { GlButton, GlSkeletonLoader, GlAlert, GlBadge, GlLink, GlIcon } from '@gitlab/ui';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { i18n, FEEDBACK_LINK_URL } from '../constants';

export default {
  name: 'AiGenieChat',
  components: {
    GlButton,
    GlAlert,
    GlBadge,
    GlLink,
    GlIcon,
    GlSkeletonLoader,
    CodeBlockHighlighted,
  },
  directives: {
    SafeHtml,
  },
  props: {
    content: {
      type: String,
      required: false,
      default: '',
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
    snippetLanguage: {
      type: String,
      required: false,
      default: 'text',
    },
    selectedText: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      forceHiddenCodeExplanation: false,
    };
  },
  watch: {
    isLoading(newVal) {
      if (newVal) {
        this.forceHiddenCodeExplanation = false;
      }
    },
  },
  methods: {
    closeCodeExplanation() {
      this.forceHiddenCodeExplanation = true;
    },
  },
  i18n,
  feedbackLinkUrl: FEEDBACK_LINK_URL,
};
</script>
<template>
  <aside
    v-if="!forceHiddenCodeExplanation"
    class="markdown-code-block gl-fixed gl-top-half gl-right-0 gl-bg-white gl-w-40p gl-rounded-top-left-base gl-rounded-bottom-left-base gl-border gl-border-r-none gl-font-sm gl-max-h-full gl-overflow-y-auto"
    style="transform: translate(0px, -50%)"
    role="complementary"
    data-testid="chat-component"
  >
    <header class="gl-p-5 gl-display-flex gl-justify-content-start gl-align-items-center">
      <h3 class="gl-font-base gl-m-0">{{ $options.i18n.GENIE_CHAT_TITLE }}</h3>
      <gl-badge class="gl-mx-4" variant="info" size="md"
        >{{ $options.i18n.EXPERIMENT_BADGE }}
      </gl-badge>
      <gl-button
        category="tertiary"
        variant="default"
        icon="close"
        size="small"
        class="gl-p-0! gl-ml-auto"
        :aria-label="$options.i18n.GENIE_CHAT_CLOSE_LABEL"
        @click="closeCodeExplanation"
      />
    </header>
    <gl-alert
      :dismissible="false"
      variant="warning"
      class="gl-mb-5 gl-border-t gl-font-sm"
      role="alert"
      data-testid="chat-legal-warning"
      primary-button-link="https://internal-handbook.gitlab.io/handbook/product/ai-strategy/ai-integration-effort/legal_restrictions/"
      :primary-button-text="__('Read more')"
    >
      <strong v-safe-html="$options.i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI"></strong>
      <p v-safe-html="$options.i18n.GENIE_CHAT_LEGAL_NOTICE"></p>
    </gl-alert>
    <code-block-highlighted
      :language="snippetLanguage"
      :code="selectedText"
      max-height="20rem"
      class="gl-border-t gl-border-b gl-rounded-0! gl-mb-0 gl-overflow-y-auto"
    />
    <section class="gl-bg-gray-10 gl-p-5">
      <gl-skeleton-loader v-if="isLoading" />
      <div v-else>
        <gl-alert
          v-if="error"
          :dismissible="false"
          variant="danger"
          class="gl-mb-0"
          role="alert"
          data-testid="chat-error"
          ><span v-safe-html="error"></span
        ></gl-alert>
        <div
          v-else
          v-safe-html="content"
          class="md ai-genie-chat-message"
          data-testid="chat-content"
        ></div>
      </div>
      <gl-link
        :href="$options.feedbackLinkUrl"
        data-testid="feedback-link"
        target="_blank"
        rel="noopener noreferrer"
        class="gl-display-inline-block gl-mt-4"
      >
        <gl-icon name="comment" class="gl-mr-2" />
        {{ $options.i18n.FEEDBACK_LINK }}
      </gl-link>
    </section>
  </aside>
</template>
