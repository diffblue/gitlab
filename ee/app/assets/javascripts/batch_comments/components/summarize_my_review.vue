<script>
import { GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { v4 as uuidv4 } from 'uuid';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER, TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import aiSummarizeReviewMutation from '../graphql/summarize_review.mutation.graphql';

export default {
  apollo: {
    $subscribe: {
      summarizeReview: {
        query: aiResponseSubscription,
        variables() {
          return {
            resourceId: this.resourceId,
            userId: convertToGraphQLId(TYPENAME_USER, window.gon.current_user_id),
            clientSubscriptionId: this.clientSubscriptionId,
          };
        },
        skip() {
          return !this.loading;
        },
        result({ data }) {
          const responseBody = data.aiCompletionResponse?.responseBody;
          const errors = data.aiCompletionResponse?.errors;

          if (errors?.length) {
            createAlert({ message: errors[0] });
            this.loading = false;
          } else if (responseBody) {
            this.$emit('input', responseBody);

            this.loading = false;
          }
        },
      },
    },
  },
  components: {
    GlButton,
  },
  props: {
    id: {
      required: true,
      type: Number,
    },
  },
  data() {
    return {
      loading: false,
      clientSubscriptionId: uuidv4(),
    };
  },
  computed: {
    resourceId() {
      return convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.id);
    },
  },
  methods: {
    triggerAiMutation() {
      this.loading = true;

      try {
        this.$apollo.mutate({
          mutation: aiSummarizeReviewMutation,
          variables: {
            resourceId: this.resourceId,
            clientSubscriptionId: this.clientSubscriptionId,
          },
        });
      } catch (e) {
        Sentry.captureException(e);

        createAlert({
          message: __('There was an summarizing your pending comments.'),
          primaryButton: {
            text: __('Try again'),
            clickHandler: () => this.triggerAiMutation(),
          },
        });

        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <gl-button
    icon="tanuki-ai"
    :loading="loading"
    data-testid="mutation-trigger"
    @click="triggerAiMutation"
  >
    {{ __('Summarize my pending comments') }}
  </gl-button>
</template>
