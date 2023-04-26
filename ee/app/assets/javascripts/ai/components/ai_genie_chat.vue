<script>
import {
  GlButton,
  GlSkeletonLoader,
  GlAlert,
  GlBadge,
  GlFormInputGroup,
  GlFormInput,
  GlForm,
} from '@gitlab/ui';
import { renderMarkdown } from '~/notes/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { i18n, GENIE_CHAT_MODEL_ROLES } from '../constants';

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
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
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
  },
  data() {
    return {
      isHidden: false,
      prompt: '',
    };
  },
  computed: {
    isChatAvaiable() {
      return this.glFeatures.explainCodeChat;
    },
  },
  watch: {
    async isLoading() {
      this.isHidden = false;
      const rect = this.$refs.lastMessage?.at(0)?.getBoundingClientRect();
      if (rect) {
        await this.$nextTick();
        this.$el.scrollTop += rect.bottom;
      }
    },
    messages() {
      this.prompt = '';
    },
  },
  methods: {
    hideChat() {
      this.isHidden = true;
      this.$emit('chat-hidden');
    },
    sendChatPrompt() {
      if (this.prompt) {
        this.$emit('send-chat-prompt', this.prompt);
      }
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
    class="markdown-code-block gl-drawer gl-drawer-default gl-h-auto gl-max-h-full gl-bottom-0 gl-z-index-200 gl-shadow-none gl-border-l gl-border-t"
    role="complementary"
    data-testid="chat-component"
    style="scroll-behavior: smooth"
  >
    <header
      class="gl-drawer-header gl-drawer-header-sticky gl-p-5 gl-display-flex gl-justify-content-start gl-align-items-center gl-z-index-200"
    >
      <h3 class="gl-font-base gl-m-0">
        <slot name="title"></slot>
      </h3>
      <gl-badge class="gl-mx-4" variant="info" size="md"
        >{{ $options.i18n.EXPERIMENT_BADGE }}
      </gl-badge>
      <gl-button
        category="tertiary"
        variant="default"
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
      class="gl-font-sm gl-mb-2 gl-border-b"
      role="alert"
      data-testid="chat-legal-warning"
      primary-button-link="https://internal-handbook.gitlab.io/handbook/product/ai-strategy/ai-integration-effort/legal_restrictions/"
      :primary-button-text="__('Read more')"
    >
      <strong v-safe-html="$options.i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI"></strong>
      <p v-safe-html="$options.i18n.GENIE_CHAT_LEGAL_NOTICE"></p>
    </gl-alert>
    <div>
      <slot name="hero"></slot>

      <section class="gl-bg-gray-10">
        <div v-if="isLoading && !messages.length" class="gl-p-5">
          <gl-skeleton-loader />
        </div>
        <div v-else>
          <div
            v-for="(message, index) in messages"
            :key="`${message.role}-${index}`"
            :ref="index === messages.length - 1 ? 'lastMessage' : undefined"
            class="gl-p-5 ai-genie-chat-message gl-text-gray-600"
            :class="{
              'gl-bg-white gl-border-t gl-border-b':
                message.role === $options.GENIE_CHAT_MODEL_ROLES.user,
            }"
          >
            <div v-safe-html="renderMarkdown(message.content)"></div>
            <slot
              v-if="message.role === $options.GENIE_CHAT_MODEL_ROLES.assistant"
              name="feedback"
            ></slot>
          </div>
          <div v-if="isLoading" class="gl-p-5 gl-display-flex">
            <gl-skeleton-loader />
          </div>
          <gl-alert
            v-if="error"
            :dismissible="false"
            variant="danger"
            class="gl-mb-0"
            role="alert"
            data-testid="chat-error"
            ><span v-safe-html="error"></span
          ></gl-alert>
        </div>
      </section>
    </div>
    <footer
      v-if="messages.length > 0 && isChatAvaiable"
      class="gl-drawer-footer gl-drawer-footer-sticky gl-drawer-body-scrim-on-footer gl-p-5 gl-border-t gl-bg-white gl-mt-5"
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
              category="secondary"
              variant="info"
              class="gl-border-l-0"
              type="submit"
              :disabled="isLoading"
            />
          </template>
        </gl-form-input-group>
      </gl-form>
    </footer>
  </aside>
</template>
