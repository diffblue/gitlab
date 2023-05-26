<script>
import { GlIcon, GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __, s__, n__ } from '~/locale';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import tanukiBotMutation from 'ee/ai/graphql/tanuki_bot.mutation.graphql';
import { i18n } from 'ee/ai/constants';
import { helpCenterState } from '~/super_sidebar/constants';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import { SOURCE_TYPES, TANUKI_BOT_FEEDBACK_ISSUE_URL } from '../constants';

export default {
  name: 'TanukiBotChatApp',
  i18n: {
    gitlabChat: s__('TanukiBot|GitLab Chat'),
    giveFeedback: s__('TanukiBot|Give feedback'),
    source: __('Source'),
    experiment: __('Experiment'),
    askAQuestion: s__('TanukiBot|Ask a question about GitLab'),
    exampleQuestion: s__('TanukiBot|For example, %{linkStart}what is a fork%{linkEnd}?'),
    whatIsAForkQuestion: s__('TanukiBot|What is a fork?'),
    GENIE_CHAT_LEGAL_GENERATED_BY_AI: i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI,
  },
  components: {
    GlIcon,
    GlAlert,
    AiGenieChat,
    GlSprintf,
    GlLink,
  },
  props: {
    userId: {
      type: String,
      required: true,
    },
  },
  apollo: {
    // https://apollo.vuejs.org/guide/apollo/subscriptions.html#simple-subscription
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        variables() {
          return {
            resourceId: this.userId,
            userId: this.userId,
          };
        },
        result({ data }) {
          this.receiveTanukiBotMessage(data);
        },
        error() {
          this.tanukiBotMessageError();
        },
      },
    },
  },
  data() {
    return {
      helpCenterState,
    };
  },
  computed: {
    ...mapState(['loading', 'messages']),
  },
  methods: {
    ...mapActions(['sendUserMessage', 'receiveTanukiBotMessage', 'tanukiBotMessageError']),
    sendMessage(question) {
      this.sendUserMessage(question);

      this.$apollo
        .mutate({
          mutation: tanukiBotMutation,
          variables: {
            question,
            resourceId: this.userId,
          },
        })
        .catch(() => {
          this.tanukiBotMessageError();
        });
    },
    closeDrawer() {
      this.helpCenterState.showTanukiBotChatDrawer = false;
    },
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
    messageHasSources(msg) {
      return msg.sources?.length > 0;
    },
    messageSourceLabel(msg) {
      return n__('TanukiBot|Source', 'TanukiBot|Sources', msg.sources?.length);
    },
  },
  TANUKI_BOT_FEEDBACK_ISSUE_URL,
};
</script>

<template>
  <div>
    <ai-genie-chat
      v-if="helpCenterState.showTanukiBotChatDrawer"
      :is-loading="loading"
      :messages="messages"
      :full-screen="true"
      is-chat-available
      @send-chat-prompt="sendMessage"
      @chat-hidden="closeDrawer"
    >
      <template #title>
        {{ $options.i18n.gitlabChat }}
      </template>

      <template #subheader>
        <gl-alert
          :dismissible="false"
          variant="tip"
          :show-icon="false"
          class="gl-text-center gl-mx-n5 gl-border-t gl-p-4 gl-text-gray-500 gl-bg-gray-10 legal-warning gl-max-w-full"
          role="alert"
          data-testid="chat-legal-warning"
        >
          <span>{{ $options.i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI }}</span>
        </gl-alert>
      </template>

      <template #feedback="slotProps">
        <div
          v-if="messageHasSources(slotProps.message)"
          class="gl-mt-4 gl-mr-3 gl-text-gray-600"
          data-testid="tanuki-bot-chat-message-sources"
        >
          <span>{{ messageSourceLabel(slotProps.message) }}:</span>
          <ul class="gl-list-style-none gl-p-0 gl-m-0">
            <li
              v-for="(source, index) in slotProps.message.sources"
              :key="index"
              class="gl-display-flex gl-pt-3"
            >
              <gl-icon
                v-if="source.source_type"
                :name="getSourceIcon(source.source_type)"
                class="gl-flex-shrink-0 gl-mr-2"
              />
              <gl-link :href="source.source_url">{{ getSourceTitle(source) }}</gl-link>
            </li>
          </ul>
        </div>
        <div class="gl-display-flex gl-align-items-flex-end gl-mt-4">
          <gl-link
            class="gl-ml-auto gl-white-space-nowrap gl-text-gray-600"
            :href="$options.TANUKI_BOT_FEEDBACK_ISSUE_URL"
            target="_blank"
            ><gl-icon name="comment" /> {{ $options.i18n.giveFeedback }}</gl-link
          >
        </div>
      </template>

      <template #input-help>
        <div class="gl-text-gray-500 gl-my-3">
          <gl-sprintf :message="$options.i18n.exampleQuestion">
            <template #link="{ content }">
              <gl-link
                class="gl-text-gray-500 gl-text-decoration-underline"
                @click="sendMessage($options.i18n.whatIsAForkQuestion)"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </div>
      </template>
    </ai-genie-chat>
    <div
      v-if="helpCenterState.showTanukiBotChatDrawer"
      class="modal-backdrop tanuki-bot-backdrop"
      data-testid="tanuki-bot-chat-drawer-backdrop"
      @click="closeDrawer"
    ></div>
  </div>
</template>
