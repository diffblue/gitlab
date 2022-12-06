<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'ProductAnalyticsApp',
  components: {
    GlLoadingIcon,
    OnboardingView: () => import('ee/product_analytics/onboarding/onboarding_view.vue'),
    DashboardsView: () => import('ee/product_analytics/dashboards/dashboards_view.vue'),
  },
  inject: { jitsuKey: { default: null } },
  data() {
    return {
      isLoading: false,
      isOnboarding: false,
    };
  },
  created() {},
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-7" />
  <onboarding-view v-else-if="isOnboarding" />
  <dashboards-view v-else />
</template>
