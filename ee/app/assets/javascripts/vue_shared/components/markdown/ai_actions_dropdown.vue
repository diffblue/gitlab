<script>
import { GlCollapsibleListbox, GlButton, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { updateText } from '~/lib/utils/text_markdown';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import { TYPENAME_USER, TYPENAME_ISSUE } from '~/graphql_shared/constants';

export const MAX_REQUEST_TIMEOUT = 1000 * 15; // 15 seconds
export const ACTIONS = {
  SUMMARIZE_COMMENTS: 'SUMMARIZE_COMMENTS',
};

export default {
  components: {
    GlCollapsibleListbox,
    GlButton,
    GlLoadingIcon,
    GlIcon,
  },
  props: {
    issuableId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      error: null,
      aiCompletionResponse: {},
    };
  },
  computed: {
    subscriptionVariables() {
      return {
        userId: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
        resourceId: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
      };
    },
  },
  destroyed() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  },
  apollo: {
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        // Apollo wants to write the subscription result to the cache, but we have none because we also
        // don't have a query. We only use this subscription as a notification.
        fetchPolicy: fetchPolicies.NO_CACHE,
        variables() {
          return this.subscriptionVariables;
        },
        result({ data }) {
          this.loading = false;

          if (this.timeout) {
            clearTimeout(this.timeout);
          }

          if (data.error) {
            this.handleError();
            return;
          }

          if (data?.aiCompletionResponse?.responseBody) {
            const textArea = this.$el.closest('.md-area')?.querySelector('textarea');
            const generatedByText = `${data.aiCompletionResponse.responseBody}\n***\n_${__(
              'This comment was generated using OpenAI',
            )}_`;
            if (textArea) {
              updateText({
                textArea,
                tag: generatedByText,
                cursorOffset: 0,
                wrap: false,
              });
            }
          }
        },
      },
    },
  },
  methods: {
    onSelect(action) {
      if (this.loading) {
        return;
      }

      const input = this.getInputForAction(action);

      if (!input) {
        return;
      }

      this.loading = true;
      this.timeout = window.setTimeout(this.handleError, MAX_REQUEST_TIMEOUT);

      this.$apollo
        .mutate({ mutation: aiActionMutation, variables: { input } })
        .then(({ data: { aiAction } }) => {
          if (aiAction.errors.length > 0) {
            this.handleError();
            return;
          }
          this.$apollo.subscriptions.aiCompletionResponse.start();
        })
        .catch(this.handleError);
    },
    getInputForAction(action) {
      if (action === ACTIONS.SUMMARIZE_COMMENTS) {
        return {
          summarizeComments: {
            resourceId: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
          },
        };
      }
      return null;
    },
    handleError(error) {
      const alertOptions = error ? { captureError: true, error } : {};
      createAlert({ message: __('Something went wrong'), ...alertOptions });
      this.loading = false;
    },
  },
  availableActions: [
    {
      value: ACTIONS.SUMMARIZE_COMMENTS,
      text: __('Summarize comments'),
      description: __('Creates a summary of all comments'),
    },
  ],
};
</script>

<template>
  <gl-collapsible-listbox
    :header-text="__('AI actions')"
    :items="$options.availableActions"
    placement="right"
    class="comment-template-dropdown"
    @select="onSelect"
  >
    <template #toggle>
      <gl-button category="tertiary" class="gl-px-3!" :disabled="loading">
        <gl-loading-icon v-if="loading" />
        <gl-icon v-else name="tanuki" />
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <div class="gl-display-flex js-comment-template-content">
        <div class="gl-font-sm">
          <strong>{{ item.text }}</strong>
          <br /><span>{{ item.description }}</span>
        </div>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
