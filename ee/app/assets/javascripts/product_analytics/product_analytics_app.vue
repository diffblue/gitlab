<script>
import OnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';

export default {
  name: 'ProductAnalyticsApp',
  components: {
    OnboardingView,
    DashboardsView: () => import('ee/analytics/analytics_dashboards/dashboards_app.vue'),
  },
  data() {
    return {
      setupNeeded: true,
    };
  },
  methods: {
    onComplete() {
      this.setupNeeded = false;
    },
  },
};
</script>

<template>
  <onboarding-view v-if="setupNeeded" @complete="onComplete" />
  <dashboards-view v-else />
</template>
