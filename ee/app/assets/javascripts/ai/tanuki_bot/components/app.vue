<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __, s__, n__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpCenterState } from '~/super_sidebar/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import getAiMessages from 'ee/ai/graphql/get_ai_messages.query.graphql';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';
import tanukiBotMutation from 'ee/ai/graphql/tanuki_bot.mutation.graphql';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import { i18n, GENIE_CHAT_RESET_MESSAGE } from 'ee/ai/constants';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import { SOURCE_TYPES, TANUKI_BOT_TRACKING_EVENT_NAME } from '../constants';

export default {
  name: 'TanukiBotChatApp',
  i18n: {
    gitlabChat: s__('TanukiBot|GitLab Duo Chat'),
    giveFeedback: s__('TanukiBot|Give feedback'),
    source: __('Source'),
    experiment: __('Experiment'),
    askAQuestion: s__('TanukiBot|Ask a question about GitLab'),
    exampleQuestion: s__('TanukiBot|For example, %{linkStart}what is a fork%{linkEnd}?'),
    whatIsAForkQuestion: s__('TanukiBot|What is a fork?'),
    GENIE_CHAT_LEGAL_GENERATED_BY_AI: i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI,
    predefinedPrompts: [
      __('How do I change my password in GitLab?'),
      __('How do I fork a project?'),
      __('How do I clone a repository?'),
      __('How do I create a template?'),
    ],
  },
  trackingEventName: TANUKI_BOT_TRACKING_EVENT_NAME,
  components: {
    GlIcon,
    AiGenieChat,
    GlLink,
    UserFeedback,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    userId: {
      type: String,
      required: true,
    },
    resourceId: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    // https://apollo.vuejs.org/guide/apollo/subscriptions.html#simple-subscription
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        variables() {
          return {
            resourceId: this.resourceId || this.userId,
            userId: this.userId,
          };
        },
        result({ data }) {
          this.addDuoChatMessage(data?.aiCompletionResponse);
        },
        error(err) {
          this.addDuoChatMessage({
            errors: [err],
          });
        },
      },
    },
    aiMessages: {
      query: getAiMessages,
      result({ data }) {
        if (data?.aiMessages?.nodes?.length) {
          this.setMessages(data.aiMessages.nodes);
        }
      },
      error(err) {
        this.addDuoChatMessage({
          errors: [err],
        });
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
    ...mapActions(['addDuoChatMessage', 'setMessages', 'setLoading']),
    sendMessage(question) {
      if (question !== GENIE_CHAT_RESET_MESSAGE) {
        this.setLoading();
      }
      const mutation = this.glFeatures.gitlabDuo ? chatMutation : tanukiBotMutation;
      this.$apollo
        .mutate({
          mutation,
          variables: {
            question,
            resourceId: this.resourceId || this.userId,
          },
        })
        .then(({ data: { aiAction = {} } = {} }) => {
          this.addDuoChatMessage({
            ...aiAction,
            content: question,
          });
        })
        .catch((err) => {
          this.setLoading(false);
          this.addDuoChatMessage({
            errors: [err],
          });
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
};
</script>

<template>
  <div>
    <ai-genie-chat
      v-if="helpCenterState.showTanukiBotChatDrawer"
      :is-loading="loading"
      :messages="messages"
      :full-screen="true"
      :predefined-prompts="$options.i18n.predefinedPrompts"
      is-chat-available
      @send-chat-prompt="sendMessage"
      @chat-hidden="closeDrawer"
    >
      <template #title>
        {{ $options.i18n.gitlabChat }}
      </template>

      <template #feedback="{ message, promptLocation }">
        <div
          v-if="messageHasSources(message)"
          class="gl-mt-4 gl-mr-3 gl-text-gray-600"
          data-testid="tanuki-bot-chat-message-sources"
        >
          <span>{{ messageSourceLabel(message) }}:</span>
          <ul class="gl-list-style-none gl-p-0 gl-m-0">
            <li
              v-for="(source, index) in message.sources"
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
          <user-feedback
            :event-name="$options.trackingEventName"
            :prompt-location="promptLocation"
          />
        </div>
      </template>
    </ai-genie-chat>
  </div>
</template>
