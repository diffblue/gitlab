import Vue from 'vue';
import VueRouter from 'vue-router';
import { convertToSentenceCase } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import ProductAnalyticsOnboardingSetup from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import DashboardsList from './components/dashboards_list.vue';
import AnalyticsDashboard from './components/analytics_dashboard.vue';
import AnalyticsVisualizationDesigner from './components/analytics_visualization_designer.vue';

Vue.use(VueRouter);

export default (base, breadcrumbState) => {
  return new VueRouter({
    mode: 'history',
    base,
    routes: [
      {
        name: 'index',
        path: '/',
        component: DashboardsList,
        meta: {
          getName: () => s__('Analytics|Analytics dashboards'),
          root: true,
        },
      },
      {
        name: 'visualization-designer',
        path: '/visualization-designer',
        component: AnalyticsVisualizationDesigner,
        meta: {
          getName: () => s__('Analytics|Visualization designer'),
        },
      },
      {
        name: 'product-analytics-onboarding',
        path: '/product-analytics-onboarding',
        component: ProductAnalyticsOnboardingView,
        meta: {
          getName: () => s__('ProductAnalytics|Product analytics onboarding'),
        },
      },
      {
        name: 'instrumentation-detail',
        path: '/product-analytics-setup',
        component: ProductAnalyticsOnboardingSetup,
        meta: {
          getName: () => s__('ProductAnalytics|Product analytics onboarding'),
        },
      },
      {
        name: 'dashboard-new',
        path: '/new',
        component: AnalyticsDashboard,
        props: {
          isNewDashboard: true,
        },
        meta: {
          getName: () => s__('Analytics|New dashboard'),
        },
      },
      {
        name: 'dashboard-detail',
        path: '/:slug',
        component: AnalyticsDashboard,
        meta: {
          getName: () => convertToSentenceCase(breadcrumbState.name),
        },
      },
    ],
  });
};
