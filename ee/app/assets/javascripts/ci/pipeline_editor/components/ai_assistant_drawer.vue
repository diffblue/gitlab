<script>
import { produce } from 'immer';
import * as Sentry from '@sentry/browser';
import getPipelineEditorAiChat from 'ee/ci/pipeline_editor/graphql/queries/pipeline_editor_get_chat_history.query.graphql';
import sendChatMessage from 'ee/ci/pipeline_editor/graphql/mutations/pipeline_editor_send_chat.mutation.graphql';
import { s__ } from '~/locale';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import AiChat from './pipeline_editor_chat.vue';

export default {
  components: {
    AiChat,
    UserFeedback,
  },
  inject: ['projectFullPath'],
  trackingEventName: 'pipeline_editor_chat',
  props: {
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      project: {
        aiConversations: {
          ciConfigMessages: {
            nodes: [],
          },
        },
      },
      userInput: '',
    };
  },
  apollo: {
    project: {
      query: getPipelineEditorAiChat,
      variables() {
        return {
          project: this.projectFullPath,
        };
      },
      pollInterval() {
        return this.isVisible && this.isWaitingForAssistantResponse ? 3000 : null;
      },
    },
  },
  computed: {
    messages() {
      if (this.project.aiConversations.ciConfigMessages.nodes.length > 0) {
        return this.project.aiConversations.ciConfigMessages.nodes.filter(
          (message) => message.content,
        );
      }

      return [
        {
          role: 'SYSTEM',
          content: 'Please, ask the bot to generate .gitlab-ci.yaml file for you',
        },
      ];
    },
    chatError() {
      if (this.lastReceivedMessage?.errors) {
        return this.lastReceivedMessage.errors.join('\n');
      }

      return '';
    },
    lastReceivedMessage() {
      const messageNodes = this.project.aiConversations.ciConfigMessages.nodes;
      return messageNodes[messageNodes.length - 1];
    },
    isWaitingForAssistantResponse() {
      return this.messages[this.messages.length - 1]?.role === 'user' && this.chatError === '';
    },
  },
  errorCaptured(error) {
    Sentry.withScope((scope) => {
      scope.setTag('vue_component', 'PipelineEditorAiAssistantDrawer');

      Sentry.captureException(error);
    });
  },
  methods: {
    closeDrawer() {
      this.$emit('close-ai-assistant-drawer');
    },
    submitPrompt(value) {
      this.$apollo.mutate({
        mutation: sendChatMessage,
        variables: {
          project: this.projectFullPath,
          content: value,
        },
        optimisticResponse: {
          ciAiGenerateConfig: {
            __typename: 'CiAiGenerateConfigPayload',
            errors: [],
            userMessage: {
              __typename: 'AiMessageType',
              id: 'unknown',
              role: 'user',
              content: value,
              errors: [],
            },
          },
        },
        update: (cache, response) => {
          const queryParam = {
            query: getPipelineEditorAiChat,
            variables: {
              project: this.projectFullPath,
            },
          };
          const { userMessage } = response.data.ciAiGenerateConfig;
          const previousData = cache.readQuery(queryParam);

          const newData = produce(previousData, (draftState) => {
            draftState.project.aiConversations.ciConfigMessages.nodes.push(userMessage);
          });

          cache.writeQuery({ ...queryParam, data: newData });
        },
      });
    },
  },
  i18n: {
    title: s__('PipelinesAiAssistant|Chat with AI assistant'),
  },
};
</script>
<template>
  <ai-chat
    v-if="isVisible"
    :is-loading="isWaitingForAssistantResponse"
    :is-chat-available="true"
    :messages="messages"
    :error="chatError"
    @chat-hidden="closeDrawer"
    @send-chat-prompt="submitPrompt"
  >
    <template #title>
      {{ $options.i18n.title }}
    </template>
    <template #feedback="{ promptLocation }">
      <user-feedback :event-name="$options.trackingEventName" :promt-location="promptLocation" />
    </template>
  </ai-chat>
</template>
