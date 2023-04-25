<script>
import { GlButton, GlDisclosureDropdown, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';

export default {
  components: {
    GlDisclosureDropdown,
    GlButton,
    GlLoadingIcon,
    GlIcon,
  },
  props: {
    actions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      errorAlert: null,
    };
  },
  computed: {
    subscriptionVariables() {
      return this.actions.reduce((acc, action) => {
        if (action.subscriptionVariables) {
          Object.assign(acc, action.subscriptionVariables());
        }
        return acc;
      }, {});
    },
    availableActions() {
      const items = this.actions.map((item) => {
        const action = item.apolloMutation ? this.onApolloAction : this.onAbstractAction;
        return {
          ...item,
          text: item.title,
          action,
          extraAttrs: {
            disabled: this.loading,
            title: this.loading ? __('Please wait for the current action to complete') : null,
          },
        };
      });
      return [
        {
          name: __('AI actions'),
          items,
        },
      ];
    },
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
        error(error) {
          this.handleError(error);
          this.afterAction();
        },
        result({ data }) {
          this.loading = false;

          if (data.error) {
            this.handleError(new Error(data.error));
            this.afterAction();
            return;
          }

          if (data?.aiCompletionResponse?.responseBody) {
            this.insertResponse(data.aiCompletionResponse.responseBody);
          }
        },
      },
    },
  },
  methods: {
    insertResponse(response) {
      this.$emit('input', response);
    },
    beforeAction() {
      if (this.loading) {
        return false;
      }

      this.errorAlert?.dismiss();

      this.loading = true;
      return true;
    },
    afterAction() {
      this.loading = false;
    },
    onAbstractAction(item) {
      if (!this.beforeAction()) return;
      item
        .handler()
        .then((response) => {
          this.insertResponse(response);
        })
        .catch(this.handleError)
        .finally(this.afterAction);
    },
    onApolloAction(item) {
      if (!this.beforeAction()) return;
      this.$apollo
        .mutate(item.apolloMutation())
        .then(({ data: { aiAction } }) => {
          if (aiAction.errors.length > 0) {
            this.handleError(new Error(aiAction.errors));
            this.afterAction();
            return;
          }
          this.$apollo.subscriptions.aiCompletionResponse.start();
        })
        .catch((error) => {
          this.handleError(error);
          this.afterAction();
        });
    },
    handleError(error) {
      const alertOptions = error ? { captureError: true, error } : {};
      this.errorAlert = createAlert({
        message: error ? error.message : __('Something went wrong'),
        ...alertOptions,
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    :items="availableActions"
    placement="right"
    class="comment-template-dropdown"
    no-caret
    @action="$refs.dropdown.close()"
  >
    <template #toggle>
      <gl-button category="tertiary" class="gl-px-3!">
        <gl-loading-icon v-if="loading" />
        <gl-icon v-else name="tanuki" />
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <div class="gl-display-flex js-comment-template-content">
        <div class="gl-font-sm">
          <strong>{{ item.title }}</strong>
          <br /><span>{{ item.description }}</span>
        </div>
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
