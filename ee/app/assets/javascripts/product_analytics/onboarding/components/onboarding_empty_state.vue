<script>
import { GlButton, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { EMPTY_STATE_I18N } from '../constants';
import initializeProductAnalyticsMutation from '../../graphql/mutations/initialize_product_analytics.mutation.graphql';

export default {
  name: 'ProductAnalyticsEmptyState',
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
  },
  inject: {
    projectFullPath: {
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
      return this.loading ? EMPTY_STATE_I18N.loading.title : EMPTY_STATE_I18N.empty.title;
    },
    description() {
      return this.loading
        ? EMPTY_STATE_I18N.loading.description
        : EMPTY_STATE_I18N.empty.description;
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
            projectPath: this.projectFullPath,
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
  i18n: EMPTY_STATE_I18N,
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
          {{ $options.i18n.empty.setUpBtnText }}
        </gl-button>
        <gl-button :href="$options.docsPath" data-testid="learn-more-btn">
          {{ $options.i18n.empty.learnMoreBtnText }}
        </gl-button>
      </template>
      <gl-loading-icon v-else size="lg" class="gl-mt-5" />
    </template>
  </gl-empty-state>
</template>
