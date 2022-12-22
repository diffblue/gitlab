<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';
import { hasAnalyticsData } from './dashboards/data_sources/cube_analytics';

const NO_PROJECT_INSTANCE = 'no_project_instance';
const NO_INSTANCE_DATA = 'no_instance_data';
const SHOW_DASHBOARDS = 'show_dashboards';

export default {
  name: 'ProductAnalyticsApp',
  components: {
    GlLoadingIcon,
    OnboardingView: () => import('ee/product_analytics/onboarding/onboarding_view.vue'),
    OnboardingSetup: () => import('ee/product_analytics/onboarding/onboarding_setup.vue'),
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
    const status = await this.getOnboardingStatus();

    this.isOnboarding = status === NO_PROJECT_INSTANCE;
    this.needsSetup = status === NO_INSTANCE_DATA;
    this.isLoading = false;
  },
  methods: {
    async getOnboardingStatus() {
      try {
        if (!this.jitsuKey) {
          return NO_PROJECT_INSTANCE;
        }

        const hasData = await hasAnalyticsData(this.projectId);

        if (!hasData) {
          return NO_INSTANCE_DATA;
        }

        return SHOW_DASHBOARDS;
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
  <onboarding-setup v-else-if="needsSetup" />
  <dashboards-view v-else-if="!hasError" />
</template>
