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
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { i18n, GENIE_CHAT_MODEL_ROLES } from '../constants';
import AiGenieLoader from './ai_genie_loader.vue';
import AiPredefinedPrompts from './ai_predefined_prompts.vue';

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
  },
  watch: {
    async isLoading() {
      this.isHidden = false;
      await this.$nextTick();
      if (this.$refs.lastMessage?.length) {
        this.$refs.lastMessage
          .at(0)
          .scrollIntoView({ behavior: 'smooth', block: 'start', inline: 'nearest' });
      }
    },
    messages() {
      this.prompt = '';
    },
  },
  async mounted() {
    await this.$nextTick();

    if (this.$refs.drawer) {
      this.$refs.drawer.scrollTop = this.$refs.drawer.scrollHeight;
    }
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
    sendPredefinedPrompt(prompt) {
      this.prompt = prompt;
      this.sendChatPrompt();
    },
    getPromptLocation(index) {
      return index ? 'after_content' : 'before_content';
    },
    isLastMessage(index) {
      return index === this.messages.length - 1;
    },
    isAssistantMessage(message) {
      return message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.assistant;
    },
    isUserMessage(message) {
      return message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.user;
    },
    getMessageContent(message) {
      return renderMarkdown(message.content || message.errors[0]);
    },
    handleScrolling: throttle(function handleScrollingDebounce() {
      const { scrollTop, offsetHeight, scrollHeight } = this.$refs.drawer;

      this.scrolledToBottom = scrollTop + offsetHeight >= scrollHeight;
    }),
    renderMarkdown,
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
          <template v-if="hasMessages || isLoading">
            <div
              v-for="(message, index) in messages"
              :key="`${message.role}-${index}`"
              :ref="isLastMessage(index) ? 'lastMessage' : undefined"
              class="gl-py-3 gl-px-4 gl-mb-4 gl-rounded-lg gl-line-height-20 ai-genie-chat-message"
              :class="{
                'gl-ml-auto gl-bg-blue-100 gl-text-blue-900 gl-rounded-bottom-right-none': isUserMessage(
                  message,
                ),
                'gl-rounded-bottom-left-none gl-text-gray-900 gl-bg-gray-50': isAssistantMessage(
                  message,
                ),
                'gl-mb-0!': isLastMessage(index) && !isLoading,
              }"
            >
              <div v-safe-html="getMessageContent(message)"></div>
              <slot
                v-if="isAssistantMessage(message)"
                name="feedback"
                :prompt-location="getPromptLocation(index)"
                :message="message"
              ></slot>
            </div>
          </template>
          <template v-else>
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
      <gl-form @submit.stop.prevent="sendChatPrompt">
        <gl-form-input-group>
          <div
            class="ai-genie-chat-input gl-flex-grow-1 gl-vertical-align-top gl-max-w-full gl-min-h-8 gl-inset-border-1-gray-400 gl-rounded-base"
            :data-value="prompt"
          >
            <gl-form-textarea
              v-model="prompt"
              data-testid="chat-prompt-input"
              class="gl-absolute gl-h-full! gl-py-4! gl-bg-transparent! gl-rounded-top-right-none gl-rounded-bottom-right-none gl-shadow-none!"
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
              variant="info"
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
