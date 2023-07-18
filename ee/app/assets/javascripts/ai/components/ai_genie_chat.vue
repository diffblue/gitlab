<script>
import emptySvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg?raw';
import {
  GlEmptyState,
  GlButton,
  GlAlert,
  GlBadge,
  GlFormInputGroup,
  GlFormTextarea,
  GlForm,
  GlIcon,
  GlFormText,
} from '@gitlab/ui';
import { throttle } from 'lodash';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { i18n, GENIE_CHAT_RESET_MESSAGE } from '../constants';
import AiGenieLoader from './ai_genie_loader.vue';
import AiPredefinedPrompts from './ai_predefined_prompts.vue';
import AiGenieChatConversation from './ai_genie_chat_conversation.vue';

export default {
  name: 'AiGenieChat',
  components: {
    GlEmptyState,
    GlButton,
    GlAlert,
    GlBadge,
    GlFormInputGroup,
    GlFormTextarea,
    GlForm,
    GlIcon,
    GlFormText,
    AiGenieLoader,
    AiPredefinedPrompts,
    AiGenieChatConversation,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagMixin()],
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
    predefinedPrompts: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      isHidden: false,
      prompt: '',
      scrolledToBottom: true,
    };
  },
  computed: {
    emptySvgPath() {
      return `data:image/svg+xml;utf8,${encodeURIComponent(emptySvg)}`;
    },
    hasMessages() {
      return this.messages.length > 0;
    },
    conversations() {
      if (!this.hasMessages) {
        return [];
      }

      let conversationIndex = 0;
      const conversations = [[]];

      this.messages.forEach((message) => {
        if (message.content === GENIE_CHAT_RESET_MESSAGE) {
          conversationIndex += 1;
          conversations[conversationIndex] = [];
        } else {
          conversations[conversationIndex].push(message);
        }
      });

      return conversations;
    },
    resetDisabled() {
      if (this.isLoading || !this.hasMessages) {
        return true;
      }

      const lastMessage = this.messages[this.messages.length - 1];
      return lastMessage.content === GENIE_CHAT_RESET_MESSAGE;
    },
  },
  watch: {
    isLoading() {
      this.isHidden = false;
      this.scrollToBottom();
    },
    async messages() {
      await this.$nextTick();
      this.prompt = '';
    },
  },
  mounted() {
    this.scrollToBottom();
  },
  methods: {
    hideChat() {
      this.isHidden = true;
      this.$emit('chat-hidden');
    },
    sendChatPrompt() {
      if (this.prompt) {
        if (this.prompt === GENIE_CHAT_RESET_MESSAGE && this.resetDisabled) {
          return;
        }
        this.$emit('send-chat-prompt', this.prompt);
      }
    },
    sendPredefinedPrompt(prompt) {
      this.prompt = prompt;
      this.sendChatPrompt();
    },
    handleScrolling: throttle(function handleScrollingDebounce() {
      const { scrollTop, offsetHeight, scrollHeight } = this.$refs.drawer;

      this.scrolledToBottom = scrollTop + offsetHeight >= scrollHeight;
    }),
    async scrollToBottom() {
      await this.$nextTick();

      if (this.$refs.drawer) {
        this.$refs.drawer.scrollTop = this.$refs.drawer.scrollHeight;
      }
    },
  },
  i18n,
};
</script>
<template>
  <aside
    v-if="!isHidden"
    ref="drawer"
    class="markdown-code-block gl-drawer gl-drawer-default gl-max-h-full gl-bottom-0 gl-z-index-9999 gl-shadow-none gl-border-l gl-border-t ai-genie-chat"
    :class="{ 'gl-h-auto': !fullScreen }"
    role="complementary"
    data-testid="chat-component"
    @scroll="handleScrolling"
  >
    <header class="gl-drawer-header gl-drawer-header-sticky gl-z-index-200 gl-p-0! gl-border-b-0">
      <div
        class="drawer-title gl-display-flex gl-justify-content-start gl-align-items-center gl-p-5"
      >
        <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-3" />
        <h3 class="gl-my-0 gl-font-size-h2">
          <slot name="title"></slot>
        </h3>
        <gl-badge class="gl-mx-4" variant="neutral" size="md"
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
      </div>

      <gl-alert
        :dismissible="false"
        variant="tip"
        :show-icon="false"
        class="gl-text-center gl-border-t gl-p-4 gl-text-gray-500 gl-bg-gray-10 legal-warning gl-max-w-full"
        role="alert"
        data-testid="chat-legal-warning"
      >
        <span>{{ $options.i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI }}</span>
      </gl-alert>

      <slot name="subheader"></slot>
    </header>

    <div class="gl-drawer-body gl-display-flex gl-flex-direction-column">
      <slot name="hero"></slot>

      <section
        class="gl-display-flex gl-flex-direction-column gl-justify-content-end gl-flex-grow-1 gl-border-b-0"
      >
        <transition-group
          tag="div"
          name="message"
          class="gl-display-flex gl-flex-direction-column gl-justify-content-end"
          :class="[
            {
              'gl-h-full': !hasMessages,
              'gl-h-auto': hasMessages,
            },
          ]"
        >
          <ai-genie-chat-conversation
            v-for="(conversation, index) in conversations"
            :key="`conversation-${index}`"
            :messages="conversation"
            :show-delimiter="index > 0"
            class="gl-display-flex gl-flex-direction-column gl-justify-content-end"
          >
            <template #feedback="{ message, promptLocation }">
              <slot name="feedback" :prompt-location="promptLocation" :message="message"></slot>
            </template>
          </ai-genie-chat-conversation>

          <template v-if="!hasMessages && !isLoading">
            <div key="empty-state" class="gl-display-flex gl-flex-grow-1">
              <gl-empty-state
                :svg-path="emptySvgPath"
                :svg-height="145"
                :title="$options.i18n.GENIE_CHAT_EMPTY_STATE_TITLE"
                :description="$options.i18n.GENIE_CHAT_EMPTY_STATE_DESC"
                class="gl-align-self-center"
              />
            </div>
            <ai-predefined-prompts
              key="predefined-prompts"
              :prompts="predefinedPrompts"
              @click="sendPredefinedPrompt"
            />
          </template>
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
          <ai-genie-loader v-if="isLoading" />
        </transition>
      </section>
    </div>
    <footer
      v-if="isChatAvailable"
      data-testid="chat-footer"
      class="gl-drawer-footer gl-drawer-footer-sticky gl-p-5 gl-border-t gl-bg-white"
      :class="{ 'gl-drawer-body-scrim-on-footer': !scrolledToBottom }"
    >
      <gl-form data-testid="chat-prompt-form" @submit.stop.prevent="sendChatPrompt">
        <gl-form-input-group>
          <div
            class="ai-genie-chat-input gl-flex-grow-1 gl-vertical-align-top gl-max-w-full gl-min-h-8 gl-inset-border-1-gray-400 gl-rounded-base"
            :data-value="prompt"
          >
            <gl-form-textarea
              v-model="prompt"
              data-testid="chat-prompt-input"
              class="gl-absolute gl-h-full! gl-py-4! gl-bg-transparent! gl-rounded-top-right-none gl-rounded-bottom-right-none gl-shadow-none! gl-text-truncate"
              :placeholder="$options.i18n.GENIE_CHAT_PROMPT_PLACEHOLDER"
              :disabled="isLoading"
              autofocus
              @keydown.enter.exact.prevent="sendChatPrompt"
            />
          </div>
          <template #append>
            <gl-button
              icon="paper-airplane"
              category="primary"
              variant="confirm"
              class="gl-absolute! gl-bottom-2 gl-right-2 gl-rounded-base!"
              type="submit"
              :disabled="isLoading"
            />
          </template>
        </gl-form-input-group>
        <gl-form-text
          class="gl-text-gray-400 gl-line-height-20 gl-mt-3"
          data-testid="chat-legal-disclaimer"
          >{{ $options.i18n.GENIE_CHAT_LEGAL_DISCLAIMER }}</gl-form-text
        >
      </gl-form>
    </footer>
  </aside>
</template>
