<script>
import { GlCard, GlIcon } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getMarkdown } from '~/rest_api';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  components: {
    GlCard,
    GlIcon,
  },
  directives: { SafeHtml },
  inject: {
    resourceGlobalId: { default: null },
  },
  props: {
    aiLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      errorAlert: null,
      aiCompletionResponse: {},
      markdown: null,
    };
  },
  computed: {
    subscriptionVariables() {
      return {
        userId: gon.current_user_id && convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
        resourceId: this.resourceGlobalId,
      };
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
        },
        async result({ data }) {
          if (data?.aiCompletionResponse?.error) {
            this.handleError();
            return;
          }

          if (data?.aiCompletionResponse?.responseBody) {
            this.$emit('set-ai-loading', false);
            const markdownResponse = await getMarkdown({
              text: data.aiCompletionResponse.responseBody,
              gfm: true,
            });
            this.markdown = markdownResponse.data.html;

            this.$nextTick(() => {
              renderGFM(this.$refs.markdown);
            });
          }
        },
      },
    },
  },
  methods: {
    handleError(error) {
      const alertOptions = error ? { captureError: true, error } : {};
      this.errorAlert = createAlert({
        message: error ? error.message : __('Something went wrong'),
        ...alertOptions,
      });
      this.$emit('set-ai-loading', false);
    },
  },
  i18n: {
    onlyVisibleToYou: __('Only visible to you'),
  },
};
</script>

<template>
  <gl-card v-if="markdown">
    <div v-if="markdown" ref="markdown" v-safe-html="markdown" class="gl-mb-2"></div>
    <hr />
    <span class="gl-text-secondary gl-font-sm"
      ><gl-icon name="eye-slash" class="gl-text-gray-400 gl-mr-1" :size="12" />{{
        $options.i18n.onlyVisibleToYou
      }}</span
    >
  </gl-card>
</template>
