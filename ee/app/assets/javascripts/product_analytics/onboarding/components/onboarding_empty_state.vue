<script>
import { GlButton, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import initializeProductAnalyticsMutation from '../../graphql/mutations/initialize_product_analytics.mutation.graphql';

export default {
  name: 'ProductAnalyticsEmptyState',
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
  },
  inject: {
    namespaceFullPath: {
      type: String,
    },
    chartEmptyStateIllustrationPath: {
      type: String,
    },
  },
  props: {
    loadingInstance: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      loading: this.loadingInstance,
      data: null,
    };
  },
  computed: {
    title() {
      return this.loading
        ? s__('ProductAnalytics|Creating your product analytics instance...')
        : s__('ProductAnalytics|Analyze your product with Product Analytics');
    },
    description() {
      return this.loading
        ? s__(
            'ProductAnalytics|This might take a while, feel free to navigate away from this page and come back later.',
          )
        : s__(
            'ProductAnalytics|Set up Product Analytics to track how your product is performing. Combine it with your GitLab data to better understand where you can improve your product and development processes.',
          );
    },
  },
  methods: {
    onConfirm() {
      this.loading = true;
      this.initialize();
    },
    onError(err) {
      this.loading = false;
      this.$emit('error', err);
    },
    async initialize() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: initializeProductAnalyticsMutation,
          variables: {
            projectPath: this.namespaceFullPath,
          },
          context: {
            isSingleRequest: true,
          },
        });

        const [error] = data?.projectInitializeProductAnalytics?.errors || [];

        if (error) {
          this.onError(new Error(error));
        } else {
          this.$emit('initialized');
        }
      } catch (err) {
        this.onError(err);
      }
    },
  },
  docsPath: helpPagePath('user/product_analytics/index'),
};
</script>

<template>
  <gl-empty-state :title="title" :svg-path="chartEmptyStateIllustrationPath">
    <template #description>
      <p class="gl-max-w-80">
        {{ description }}
      </p>
    </template>
    <template #actions>
      <template v-if="!loading">
        <gl-button variant="confirm" data-testid="setup-btn" @click="onConfirm">
          {{ s__('ProductAnalytics|Set up product analytics') }}
        </gl-button>
        <gl-button :href="$options.docsPath" data-testid="learn-more-btn">
          {{ __('Learn more') }}
        </gl-button>
      </template>
      <gl-loading-icon v-else size="lg" class="gl-mt-5" />
    </template>
  </gl-empty-state>
</template>
