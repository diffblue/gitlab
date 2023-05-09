<script>
import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import AnalyticsDashboard from './components/analytics_dashboard.vue';
import DashboardsList from './components/dashboards_list.vue';

Vue.use(GlToast);

export default {
  name: 'DashboardsApp',
  created() {
    [
      {
        name: 'index',
        path: '',
        component: DashboardsList,
      },
      {
        name: 'visualization-designer',
        path: '/visualization-designer',
        component: () =>
          import(
            'ee/analytics/analytics_dashboards/components/analytics_visualization_designer.vue'
          ),
      },
      {
        name: 'product-analytics-onboarding',
        path: '/product-analytics-onboarding',
        component: () => import('ee/product_analytics/onboarding/onboarding_view.vue'),
      },
      {
        name: 'instrumentation-detail',
        path: '/product-analytics-setup',
        component: () => import('ee/product_analytics/onboarding/onboarding_setup.vue'),
      },
      {
        name: 'dashboard-new',
        path: '/new',
        component: AnalyticsDashboard,
        props: {
          isNewDashboard: true,
        },
      },
      {
        name: 'dashboard-detail',
        path: '/:id',
        // This is the main action that occurs after the list is shown so we preload it rather than lazy importing
        component: AnalyticsDashboard,
      },
    ].forEach((route) => this.$router.addRoute(route));
  },
};
</script>

<template>
  <router-view ref="router-view" />
</template>
