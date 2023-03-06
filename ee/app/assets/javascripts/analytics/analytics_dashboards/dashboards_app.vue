<script>
import AnalyticsDashboard from './components/analytics_dashboard.vue';
import DashboardsList from './components/dashboards_list.vue';

export default {
  name: 'DashboardsApp',
  created() {
    this.$router.addRoutes([
      {
        name: 'index',
        path: '',
        component: DashboardsList,
      },
      {
        name: 'panel-designer',
        path: '/panel-designer',
        component: () =>
          import('ee/product_analytics/dashboards/components/analytics_panel_designer.vue'),
      },
      {
        name: 'instrumentation-detail',
        path: '/setup',
        component: () => import('ee/product_analytics/onboarding/onboarding_setup.vue'),
      },
      {
        name: 'dashboard-detail',
        path: '/:id',
        // This is the main action that occurs after the list is shown so we preload it rather than lazy importing
        component: AnalyticsDashboard,
      },
    ]);
  },
};
</script>

<template>
  <router-view ref="router-view" />
</template>
