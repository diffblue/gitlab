import Vue from 'vue';
import VueRouter from 'vue-router';
import { I18N_ONBOARDING_BREADCRUMB } from 'ee/product_analytics/onboarding/constants';
import { convertToSentenceCase } from '~/lib/utils/text_utility';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import ProductAnalyticsOnboardingSetup from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import DashboardsList from './components/dashboards_list.vue';
import {
  I18N_DASHBOARD_LIST_TITLE_BREADCRUMB,
  I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_BREADCRUMB,
  I18N_NEW_DASHBOARD_BREADCRUMB,
} from './constants';
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
          getName: () => I18N_DASHBOARD_LIST_TITLE_BREADCRUMB,
          root: true,
        },
      },
      {
        name: 'visualization-designer',
        path: '/visualization-designer',
        component: AnalyticsVisualizationDesigner,
        meta: {
          getName: () => I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_BREADCRUMB,
        },
      },
      {
        name: 'product-analytics-onboarding',
        path: '/product-analytics-onboarding',
        component: ProductAnalyticsOnboardingView,
        meta: {
          getName: () => I18N_ONBOARDING_BREADCRUMB,
        },
      },
      {
        name: 'instrumentation-detail',
        path: '/product-analytics-setup',
        component: ProductAnalyticsOnboardingSetup,
        meta: {
          getName: () => I18N_ONBOARDING_BREADCRUMB,
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
          getName: () => I18N_NEW_DASHBOARD_BREADCRUMB,
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
