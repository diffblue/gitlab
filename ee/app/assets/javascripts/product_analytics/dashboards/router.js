import Vue from 'vue';
import VueRouter from 'vue-router';
import DashboardsList from './components/analytics_dashboard_list.vue';
import AnalyticsDashboard from './components/analytics_dashboard.vue';
import AnalyticsWidgetDesigner from './components/analytics_widget_designer.vue';

Vue.use(VueRouter);

export default () => {
  const routes = [
    {
      name: 'index',
      path: '',
      component: DashboardsList,
    },
    {
      name: 'widget-designer',
      path: '/widget-designer',
      component: AnalyticsWidgetDesigner,
    },
    {
      name: 'dashboard-detail',
      path: '/:id',
      component: AnalyticsDashboard,
    },
  ];
  return new VueRouter({
    mode: 'history',
    base: `${
      window.location.pathname.split('/-/product_analytics/dashboards')[0]
    }/-/product_analytics/dashboards`,
    routes,
  });
};
