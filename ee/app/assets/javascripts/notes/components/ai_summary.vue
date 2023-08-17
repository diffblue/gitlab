<script>
import { GlBadge, GlIcon, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getMarkdown } from '~/rest_api';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { MAX_REQUEST_TIMEOUT } from 'ee/notes/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlLink,
    GlSkeletonLoader,
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
  mounted() {
    this.timeout = window.setTimeout(this.handleError, MAX_REQUEST_TIMEOUT);
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
        error(error) {
          this.handleError(error);
        },
        async result({ data }) {
          if (data?.aiCompletionResponse?.error) {
            this.handleError();
            return;
          }

          if (data?.aiCompletionResponse?.responseBody) {
            clearTimeout(this.timeout);
            const markdownResponse = await getMarkdown({
              text: data.aiCompletionResponse.responseBody,
              gfm: true,
            });
            this.markdown = markdownResponse.data.html;

            this.$nextTick(() => {
              this.$emit('set-ai-loading', false);
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
  feedback: {
    link: 'https://gitlab.com/gitlab-org/gitlab/-/issues/407779',
  },
  i18n: {
    onlyVisibleToYou: __('Only visible to you'),
  },
};
</script>

<template>
  <div v-if="markdown || aiLoading" class="ai-summary-card gl-rounded-base gl-border gl-bg-gray-10">
    <div class="gl-px-5 gl-py-4 gl-bg-white gl-rounded-top-base gl-border-b">
      <div class="gl-display-flex gl-align-items-center gl-gap-3">
        <gl-icon name="tanuki-ai" class="gl-text-purple-600" />
        <h5 class="gl-my-0">{{ __('AI-generated summary') }}</h5>
        <gl-badge variant="neutral">{{ __('Experiment') }}</gl-badge>
      </div>
    </div>
    <div class="gl-px-5 gl-py-4">
      <gl-skeleton-loader v-if="aiLoading" :lines="5" />
      <div v-else>
        <div v-if="markdown" ref="markdown" v-safe-html="markdown" class="gl-mb-2"></div>

        <div class="gl-text-secondary gl-font-sm">
          <gl-icon name="eye-slash" class="gl-text-gray-400 gl-mr-2" :size="12" />{{
            $options.i18n.onlyVisibleToYou
          }}
          &middot;
          <gl-link :href="$options.feedback.link" target="_blank" class="gl-font-sm">{{
            __('Leave feedback')
          }}</gl-link>
        </div>
      </div>
    </div>
  </div>
</template>
