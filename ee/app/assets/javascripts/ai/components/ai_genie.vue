<script>
import { debounce } from 'lodash';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { generatePrompt } from 'ee/ai/utils';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import { renderMarkdown } from '~/notes/utils';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import explainCodeMutation from '../graphql/explain_code.mutation.graphql';
import { i18n, AI_GENIE_DEBOUNCE } from '../constants';

const linesWithDigitsOnly = /^\d+$\n/gm;

export default {
  name: 'AiGenie',
  i18n,
  components: {
    GlButton,
    AiGenieChat,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['resourceId', 'userId'],
  props: {
    containerId: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    // https://apollo.vuejs.org/guide/apollo/subscriptions.html#simple-subscription
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        variables() {
          return {
            resourceId: this.resourceId,
            userId: this.userId,
          };
        },
        result({ data }) {
          const explanation = data.aiCompletionResponse?.responseBody;
          if (explanation) {
            this.codeExplanationLoading = false;
            this.codeExplanation = renderMarkdown(explanation);
          }
        },
        error() {
          this.codeExplanationError = this.$options.i18n.REQUEST_ERROR;
        },
        skip() {
          return !this.codeExplanationLoading;
        },
      },
    },
  },
  data() {
    return {
      codeExplanation: '',
      codeExplanationLoading: false,
      codeExplanationError: '',
      selectedText: '',
      snippetLanguage: undefined,
      shouldShowButton: false,
      container: null,
      top: null,
    };
  },
  computed: {
    shouldShowChat() {
      return this.codeExplanation || this.codeExplanationLoading || this.codeExplanationError;
    },
    rootStyle() {
      if (!this.top) return null;
      return { top: `${this.top}px` };
    },
  },
  created() {
    this.debouncedSelectionChangeHandler = debounce(this.handleSelectionChange, AI_GENIE_DEBOUNCE);
  },
  mounted() {
    document.addEventListener('selectionchange', this.debouncedSelectionChangeHandler);
  },
  beforeDestroy() {
    document.removeEventListener('selectionchange', this.debouncedSelectionChangeHandler);
  },
  methods: {
    handleSelectionChange() {
      this.container = document.getElementById(this.containerId);
      if (!this.container) {
        throw new Error(this.$options.i18n.GENIE_NO_CONTAINER_ERROR);
      }
      this.snippetLanguage = this.container.querySelector('[lang]')?.lang;

      const selection = window.getSelection();
      if (this.isWithinContainer(selection)) {
        this.setPosition(selection);
        this.shouldShowButton = true;
      } else {
        this.shouldShowButton = false;
      }
    },
    isWithinContainer(selection) {
      return (
        !selection.isCollapsed &&
        this.container.contains(selection.anchorNode) &&
        this.container.contains(selection.focusNode)
      );
    },
    setPosition(selection) {
      const { top: startSelectionTop } = selection.getRangeAt(0).getBoundingClientRect();
      const { top: finishSelectionTop } = selection
        .getRangeAt(selection.rangeCount - 1)
        .getBoundingClientRect();
      const { top: containerTop } = this.container.getBoundingClientRect();

      this.top = Math.min(startSelectionTop, finishSelectionTop) - containerTop;
    },
    async requestCodeExplanation() {
      this.codeExplanationLoading = true;
      this.selectedText = window.getSelection().toString().replace(linesWithDigitsOnly, '').trim();
      this.$apollo
        .mutate({
          mutation: explainCodeMutation,
          variables: {
            messages: generatePrompt(this.selectedText, this.filePath),
            resourceId: this.resourceId,
          },
        })
        .catch(() => {
          this.codeExplanationError = this.$options.i18n.REQUEST_ERROR;
          this.codeExplanationLoading = false;
        });
    },
  },
};
</script>
<template>
  <div class="gl-absolute gl-z-index-9999 gl-mx-n3" :style="rootStyle">
    <gl-button
      v-show="shouldShowButton"
      v-gl-tooltip
      :title="$options.i18n.GENIE_TOOLTIP"
      category="tertiary"
      variant="default"
      icon="question"
      size="small"
      class="gl-p-0! gl-display-block gl-bg-white! explain-the-code gl-rounded-full!"
      @click="requestCodeExplanation"
    />
    <ai-genie-chat
      v-if="shouldShowChat"
      :is-loading="codeExplanationLoading"
      :content="codeExplanation"
      :selected-text="selectedText"
      :error="codeExplanationError"
      :snippet-language="snippetLanguage"
    />
  </div>
</template>
