<script>
import DashboardsList from './components/analytics_dashboard_list.vue';
import AnalyticsDashboard from './components/analytics_dashboard.vue';

export default {
  name: 'ProductAnalyticsDashboardsView',
  created() {
    this.$router.addRoutes([
      {
        name: 'index',
        path: '',
        component: DashboardsList,
      },
      {
        name: 'widget-designer',
        path: '/widget-designer',
        component: () => import('./components/analytics_widget_designer.vue'),
      },
      {
        name: 'instrumentation-detail',
        path: '/setup',
        component: () => import('../onboarding/onboarding_setup.vue'),
      },
      {
        name: 'dashboard-detail',
        path: '/:id',
        component: AnalyticsDashboard,
      },
    ]);
  },
};
</script>

<template>
  <router-view ref="router-view" />
</template>
