<script>
import { GlButton, GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { i18n } from '../constants';

export default {
  name: 'AiGenieChat',
  components: {
    GlButton,
    GlAlert,
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
};
</script>
<template>
  <aside
    v-if="!forceHiddenCodeExplanation"
    class="markdown-code-block gl-fixed gl-top-half gl-right-0 gl-bg-white gl-w-40p gl-rounded-top-left-base gl-rounded-bottom-left-base gl-border gl-border-r-none gl-font-sm"
    style="transform: translate(0px, -50%)"
    role="complementary"
    data-testid="chat-component"
  >
    <header class="gl-p-5 gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <h3 class="gl-font-base gl-m-0">{{ $options.i18n.GENIE_CHAT_TITLE }}</h3>
      <gl-button
        category="tertiary"
        variant="default"
        icon="close"
        size="small"
        class="gl-p-0! gl-ml-2"
        :aria-label="$options.i18n.GENIE_CHAT_CLOSE_LABEL"
        @click="closeCodeExplanation"
      />
    </header>
    <code-block-highlighted
      :language="snippetLanguage"
      :code="selectedText"
      class="gl-border-t gl-border-b gl-rounded-0! gl-mb-0"
    />
    <section class="gl-bg-gray-10 gl-p-5">
      <gl-skeleton-loader v-if="isLoading" />
      <div v-else>
        <gl-alert v-if="error" :dismissible="false" variant="danger" class="gl-mb-0" role="alert"
          ><span v-safe-html="error"></span
        ></gl-alert>
        <div v-else v-safe-html="content" class="md" data-testid="chat-content"></div>
      </div>
    </section>
  </aside>
</template>
