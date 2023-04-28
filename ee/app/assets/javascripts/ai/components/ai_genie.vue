<script>
import { debounce } from 'lodash';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { generateExplainCodePrompt, generateChatPrompt } from 'ee/ai/utils';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import { renderMarkdown } from '~/notes/utils';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import {
  i18n,
  AI_GENIE_DEBOUNCE,
  GENIE_CHAT_MODEL_ROLES,
  EXPLAIN_CODE_TRACKING_EVENT_NAME,
} from '../constants';
import explainCodeMutation from '../graphql/explain_code.mutation.graphql';

const linesWithDigitsOnly = /^\d+$\n/gm;

export default {
  name: 'AiGenie',
  i18n,
  trackingEventName: EXPLAIN_CODE_TRACKING_EVENT_NAME,
  components: {
    GlButton,
    AiGenieChat,
    CodeBlockHighlighted,
    UserFeedback,
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
          const errors = data.aiCompletionResponse?.errors;
          if (errors && errors.length) {
            this.isLoading = false;
            this.codeExplanationError = this.$options.i18n.REQUEST_ERROR;
            return;
          }

          const explanation = data.aiCompletionResponse?.responseBody;
          if (explanation) {
            this.isLoading = false;
            this.messages.push({
              role: GENIE_CHAT_MODEL_ROLES.assistant,
              content: renderMarkdown(explanation),
            });
          }
        },
        error() {
          this.codeExplanationError = this.$options.i18n.REQUEST_ERROR;
          this.isLoading = false;
        },
      },
    },
  },
  data() {
    return {
      isLoading: false,
      codeExplanationError: '',
      selectedText: '',
      snippetLanguage: 'plaintext',
      shouldShowButton: false,
      container: null,
      top: null,
      messages: [],
    };
  },
  computed: {
    shouldShowChat() {
      return this.isLoading || this.messages.length || this.codeExplanationError;
    },
    rootStyle() {
      if (!this.top) return null;
      return { top: `${this.top}px` };
    },
    filteredMessages() {
      return this.messages.slice(2); // drop the `system` and the first `user` prompts
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
    this.messages = [];
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
    requestCodeExplanation() {
      this.messages = [];
      this.codeExplanationError = '';
      this.selectedText = window.getSelection().toString().replace(linesWithDigitsOnly, '').trim();
      const prompt = generateExplainCodePrompt(this.selectedText, this.filePath);
      this.chat(prompt);
    },
    chat(prompt) {
      this.isLoading = true;
      const handleError = (err) => {
        this.codeExplanationError = err?.message || this.$options.i18n.REQUEST_ERROR;
        this.isLoading = false;
      };
      try {
        this.messages = generateChatPrompt(prompt, this.messages);
        this.$apollo
          .mutate({
            mutation: explainCodeMutation,
            variables: {
              messages: this.messages,
              resourceId: this.resourceId,
            },
          })
          .catch((err) => {
            handleError(err);
          });
      } catch (err) {
        handleError(err);
      }
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
      :aria-label="$options.i18n.GENIE_TOOLTIP"
      category="tertiary"
      variant="default"
      icon="question"
      size="small"
      class="gl-p-0! gl-display-block gl-bg-white! explain-the-code gl-rounded-full!"
      @click="requestCodeExplanation"
    />
    <ai-genie-chat
      v-if="shouldShowChat"
      :is-loading="isLoading"
      :messages="filteredMessages"
      :error="codeExplanationError"
      @send-chat-prompt="chat"
    >
      <template #title>
        {{ $options.i18n.GENIE_CHAT_TITLE }}
      </template>
      <template #hero>
        <code-block-highlighted
          :language="snippetLanguage"
          :code="selectedText"
          max-height="20rem"
          class="gl-border-t gl-border-b gl-rounded-0! gl-mb-0 gl-overflow-y-auto"
        />
      </template>
      <template #feedback="{ promptLocation }">
        <user-feedback :event-name="$options.trackingEventName" :prompt-location="promptLocation" />
      </template>
    </ai-genie-chat>
  </div>
</template>
