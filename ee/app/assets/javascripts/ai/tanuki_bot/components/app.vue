<script>
import { GlDrawer, GlIcon, GlBadge, GlAlert } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import tanukiBotMutation from 'ee/ai/graphql/tanuki_bot.mutation.graphql';
import { i18n } from 'ee/ai/constants';
import { helpCenterState } from '~/super_sidebar/constants';
import TanukiBotChat from './tanuki_bot_chat.vue';
import TanukiBotChatInput from './tanuki_bot_chat_input.vue';

export default {
  name: 'TanukiBotChatApp',
  i18n: {
    gitlabChat: s__('TanukiBot|GitLab Chat'),
    experiment: __('Experiment'),
    GENIE_CHAT_LEGAL_GENERATED_BY_AI: i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI,
  },
  components: {
    GlIcon,
    GlDrawer,
    GlBadge,
    GlAlert,
    TanukiBotChat,
    TanukiBotChatInput,
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
  },
};
</script>

<template>
  <section>
    <gl-drawer
      data-testid="tanuki-bot-chat-drawer"
      class="tanuki-bot-chat-drawer gl-reset-line-height"
      :z-index="1000"
      :open="helpCenterState.showTanukiBotChatDrawer"
      @close="closeDrawer"
    >
      <template #title>
        <span class="gl-display-flex gl-align-items-center">
          <gl-icon name="tanuki" class="gl-text-orange-500" />
          <h3 class="gl-my-0 gl-mx-3">{{ $options.i18n.gitlabChat }}</h3>
          <gl-badge variant="muted">{{ $options.i18n.experiment }}</gl-badge>
        </span>
      </template>

      <template #header>
        <gl-alert
          :dismissible="false"
          variant="tip"
          :show-icon="false"
          class="gl-text-center gl-mx-n5 gl-mt-5 gl-border-t gl-p-4 gl-text-gray-500 gl-bg-gray-10 legal-warning"
          role="alert"
          data-testid="chat-legal-warning"
        >
          <span>{{ $options.i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI }}</span>
        </gl-alert>
      </template>

      <tanuki-bot-chat />

      <template #footer>
        <tanuki-bot-chat-input @submit="sendMessage" />
      </template>
    </gl-drawer>
    <div
      v-if="helpCenterState.showTanukiBotChatDrawer"
      class="modal-backdrop tanuki-bot-backdrop"
      data-testid="tanuki-bot-chat-drawer-backdrop"
      @click="closeDrawer"
    ></div>
  </section>
</template>
