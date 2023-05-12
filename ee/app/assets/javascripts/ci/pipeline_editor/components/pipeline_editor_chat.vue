<script>
import {
  GlButton,
  GlSkeletonLoader,
  GlAlert,
  GlBadge,
  GlFormInputGroup,
  GlFormInput,
  GlForm,
  GlIcon,
} from '@gitlab/ui';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { i18n, GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import Markdown from './markdown.vue';

export default {
  name: 'AiGenieChat',
  components: {
    GlButton,
    GlAlert,
    GlBadge,
    GlSkeletonLoader,
    GlFormInputGroup,
    GlFormInput,
    GlForm,
    GlIcon,
    Markdown,
  },
  directives: {
    SafeHtml,
  },
  props: {
    messages: {
      type: Array,
      required: false,
      default: () => [],
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    fullScreen: {
      type: Boolean,
      required: false,
      default: false,
    },
    isChatAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isHidden: false,
      prompt: '',
    };
  },
  watch: {
    async isLoading() {
      this.isHidden = false;
      await this.$nextTick();
      this.scrollToLastMessage();
    },
    messages() {
      this.prompt = '';
    },
  },
  mounted() {
    this.scrollToLastMessage('instant');
  },
  methods: {
    scrollToLastMessage(scrollBehavior = 'smooth') {
      if (this.$refs.lastMessage) {
        this.$refs.lastMessage[0]?.scrollIntoView({
          behavior: scrollBehavior,
          block: 'start',
          inline: 'nearest',
        });
      }
    },
    hideChat() {
      this.isHidden = true;
      this.$emit('chat-hidden');
    },
    sendChatPrompt() {
      if (this.prompt) {
        this.$emit('send-chat-prompt', this.prompt);
      }
    },
    getPromptLocation(index) {
      return index ? 'after_content' : 'before_content';
    },
    renderMarkdown,
  },
  i18n,
  GENIE_CHAT_MODEL_ROLES,
};
</script>
<template>
  <aside
    v-if="!isHidden"
    class="markdown-code-block gl-drawer gl-drawer-default gl-max-h-full gl-bottom-0 gl-z-index-9999 gl-shadow-none gl-border-l gl-border-t ai-genie-chat"
    :class="{ 'gl-h-auto': !fullScreen }"
    role="complementary"
    data-testid="chat-component"
  >
    <header
      class="gl-drawer-header gl-drawer-header-sticky gl-p-5 gl-display-flex gl-justify-content-start gl-align-items-center gl-z-index-200"
    >
      <gl-icon name="tanuki" class="gl-text-orange-500 gl-mr-3" />
      <h4 class="gl-my-0">
        <slot name="title"></slot>
      </h4>
      <gl-badge class="gl-mx-4" variant="muted" size="md"
        >{{ $options.i18n.EXPERIMENT_BADGE }}
      </gl-badge>
      <gl-button
        category="tertiary"
        icon="close"
        size="small"
        class="gl-p-0! gl-ml-auto"
        data-testid="chat-close-button"
        :aria-label="$options.i18n.GENIE_CHAT_CLOSE_LABEL"
        @click="hideChat"
      />
    </header>
    <gl-alert
      :dismissible="false"
      variant="warning"
      class="gl-font-sm"
      role="alert"
      data-testid="chat-legal-warning"
      primary-button-link="https://internal-handbook.gitlab.io/handbook/product/ai-strategy/ai-integration-effort/legal_restrictions/"
      :primary-button-text="__('Read more')"
    >
      <strong v-safe-html="$options.i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI"></strong>
      <p v-safe-html="$options.i18n.GENIE_CHAT_LEGAL_NOTICE"></p>
    </gl-alert>

    <div class="gl-drawer-body gl-drawer-body gl-display-flex gl-flex-direction-column">
      <slot name="hero"></slot>

      <section
        class="gl-display-flex gl-flex-direction-column gl-justify-content-end gl-flex-grow-1 gl-border-b-0"
      >
        <transition-group
          tag="div"
          name="message"
          class="gl-display-flex gl-flex-direction-column gl-justify-content-end gl-h-auto"
        >
          <div
            v-for="(message, index) in messages"
            :key="`${message.role}-${index}`"
            :ref="index === messages.length - 1 ? 'lastMessage' : undefined"
            class="gl-py-3 gl-px-4 gl-mb-4 gl-rounded-lg ai-genie-chat-message gl-shadow-sm"
            :class="{
              'gl-ml-auto gl-bg-blue-100 gl-text-blue-900 gl-rounded-bottom-right-none':
                message.role === $options.GENIE_CHAT_MODEL_ROLES.user,
              'gl-rounded-bottom-left-none gl-text-gray-900 gl-bg-gray-50':
                message.role === $options.GENIE_CHAT_MODEL_ROLES.assistant,
              'gl-mb-0!': index === messages.length - 1 && !isLoading,
            }"
          >
            <markdown :markdown="message.content" />
            <slot
              v-if="message.role === $options.GENIE_CHAT_MODEL_ROLES.assistant"
              name="feedback"
              :prompt-location="getPromptLocation(index)"
            ></slot>
          </div>
          <gl-alert
            v-if="error"
            key="error"
            :dismissible="false"
            variant="danger"
            class="gl-mb-0"
            role="alert"
            data-testid="chat-error"
            ><span v-safe-html="error"></span
          ></gl-alert>
        </transition-group>
        <transition name="loader">
          <div v-if="isLoading" class="gl-pt-0!">
            <gl-skeleton-loader />
          </div>
        </transition>
      </section>
    </div>
    <footer
      v-if="isChatAvailable"
      class="gl-drawer-footer gl-drawer-footer-sticky gl-drawer-body-scrim-on-footer gl-p-5 gl-border-t gl-bg-white"
    >
      <gl-form @submit.stop.prevent="sendChatPrompt">
        <gl-form-input-group>
          <gl-form-input
            v-model="prompt"
            data-testid="chat-prompt-input"
            :placeholder="$options.i18n.GENIE_CHAT_PROMPT_PLACEHOLDER"
            :disabled="isLoading"
          />
          <template #append>
            <gl-button
              icon="paper-airplane"
              category="primary"
              variant="info"
              class="gl-border-l-0"
              type="submit"
              :aria-label="$options.i18n.GENIE_CHAT_SUBMIT_LABEL"
              :disabled="isLoading"
            />
          </template>
        </gl-form-input-group>
      </gl-form>
    </footer>
  </aside>
</template>
