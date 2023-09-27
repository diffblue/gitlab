<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { v4 as uuidv4 } from 'uuid';
import { __, s__ } from '~/locale';
import { helpCenterState } from '~/super_sidebar/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import getAiMessages from 'ee/ai/graphql/get_ai_messages.query.graphql';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';
import Tracking from '~/tracking';
import { i18n, GENIE_CHAT_RESET_MESSAGE } from 'ee/ai/constants';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import { TANUKI_BOT_TRACKING_EVENT_NAME } from '../constants';

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
  components: {
    AiGenieChat,
  },
  mixins: [Tracking.mixin()],
  provide() {
    return {
      trackingEventName: TANUKI_BOT_TRACKING_EVENT_NAME,
    };
  },
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
        skip() {
          return !this.loading;
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
      aiCompletionResponseStream: {
        query: aiResponseSubscription,
        variables() {
          return {
            userId: this.userId,
            resourceId: this.resourceId || this.userId,
            clientSubscriptionId: this.clientSubscriptionId,
            htmlResponse: false,
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
      clientSubscriptionId: uuidv4(),
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
      this.$apollo
        .mutate({
          mutation: chatMutation,
          variables: {
            question,
            resourceId: this.resourceId || this.userId,
            clientSubscriptionId: this.clientSubscriptionId,
          },
        })
        .then(({ data: { aiAction = {} } = {} }) => {
          this.track('submit_gitlab_duo_question', {
            property: aiAction.requestId,
          });
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
    </ai-genie-chat>
  </div>
</template>
