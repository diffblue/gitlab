<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';
import { hasAnalyticsData } from './dashboards/data_sources/cube_analytics';

export default {
  name: 'ProductAnalyticsApp',
  components: {
    GlLoadingIcon,
    OnboardingView: () => import('ee/product_analytics/onboarding/onboarding_view.vue'),
    DashboardsView: () => import('ee/product_analytics/dashboards/dashboards_view.vue'),
  },
  inject: {
    jitsuKey: {
      type: String,
      default: null,
    },
    projectId: {
      type: String,
    },
  },
  data() {
    return {
      isLoading: true,
      isOnboarding: false,
      hasError: false,
    };
  },
  async created() {
    this.isOnboarding = await this.getOnboardingStatus();
    this.isLoading = false;
  },
  methods: {
    async getOnboardingStatus() {
      try {
        return !(this.jitsuKey && (await hasAnalyticsData(this.projectId)));
      } catch (error) {
        createAlert({
          message: this.$options.i18n.unhandledErrorMessage,
          captureError: true,
          error,
        });

        this.hasError = true;

        return null;
      }
    },
  },
  i18n: {
    unhandledErrorMessage: s__(
      'ProductAnalytics|An error occurred while fetching data. Refresh the page to try again.',
    ),
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-7" />
  <onboarding-view v-else-if="isOnboarding" />
  <dashboards-view v-else-if="!hasError" />
</template>
