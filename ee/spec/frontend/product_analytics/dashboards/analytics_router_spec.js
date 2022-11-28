import createAnalyticsRouter from 'ee/product_analytics/dashboards/router';
import DashboardsList from 'ee/product_analytics/dashboards/components/analytics_dashboard_list.vue';
import AnalyticsDashboard from 'ee/product_analytics/dashboards/components/analytics_dashboard.vue';
import AnalyticsWidgetDesigner from 'ee/product_analytics/dashboards/components/analytics_widget_designer.vue';

describe('Analytics Dashboard Router Spec', () => {
  it.each`
    path                   | component
    ${'/'}                 | ${DashboardsList}
    ${'/widget-designer'}  | ${AnalyticsWidgetDesigner}
    ${'/test-dashboard-1'} | ${AnalyticsDashboard}
    ${'/test-dashboard-2'} | ${AnalyticsDashboard}
  `('sets component as $component.name for path "$path"', ({ path, component }) => {
    const router = createAnalyticsRouter();

    expect(router.getMatchedComponents(path)).toContain(component);
  });
});
