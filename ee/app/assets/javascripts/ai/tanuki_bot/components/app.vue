<script>
import { GlDrawer, GlIcon, GlBadge } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import tanukiBotMutation from 'ee/ai/graphql/tanuki_bot.mutation.graphql';
import { helpCenterState } from '~/super_sidebar/constants';
import TanukiBotChat from './tanuki_bot_chat.vue';
import TanukiBotChatInput from './tanuki_bot_chat_input.vue';

export default {
  name: 'TanukiBotChatApp',
  i18n: {
    gitlabChat: s__('TanukiBot|GitLab Chat'),
    experiment: __('Experiment'),
  },
  components: {
    GlIcon,
    GlDrawer,
    GlBadge,
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
