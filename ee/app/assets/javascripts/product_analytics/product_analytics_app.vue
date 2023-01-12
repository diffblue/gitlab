<script>
import OnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import { NO_PROJECT_INSTANCE, NO_INSTANCE_DATA } from './onboarding/constants';

export default {
  name: 'ProductAnalyticsApp',
  components: {
    OnboardingView,
    DashboardsView: () => import('ee/product_analytics/dashboards/dashboards_view.vue'),
  },
  inject: {
    jitsuKey: {
      type: String,
      default: null,
    },
  },
  data() {
    return {
      onboardingStatus: this.getInitialOnboardingStatus(),
      onboardingSuccess: false,
    };
  },
  methods: {
    getInitialOnboardingStatus() {
      if (!this.jitsuKey) {
        return NO_PROJECT_INSTANCE;
      }

      // We'll let <onboarding-view> figure out if we have instance data or not
      return NO_INSTANCE_DATA;
    },
    onOnboardingUpdate(isSuccess) {
      this.onboardingStatus = null;
      this.onboardingSuccess = isSuccess;
    },
  },
};
</script>

<template>
  <onboarding-view
    v-if="onboardingStatus"
    :status="onboardingStatus"
    @complete="onOnboardingUpdate(true)"
    @error="onOnboardingUpdate(false)"
  />
  <dashboards-view v-else-if="onboardingSuccess" />
</template>
