<script>
import { GlLoadingIcon } from '@gitlab/ui';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';

// TODO: Replace the hardcoded values with API calls in https://gitlab.com/gitlab-org/gitlab/-/issues/382551
const VISUALIZATION_JSONS = {
  average_session_duration: () =>
    import(`../gl_dashboards/visualizations/average_session_duration.json`),
  average_sessions_per_user: () =>
    import(`../gl_dashboards/visualizations/average_sessions_per_user.json`),
  browsers_per_users: () => import(`../gl_dashboards/visualizations/browsers_per_users.json`),
  daily_active_users: () => import(`../gl_dashboards/visualizations/daily_active_users.json`),
  events_over_time: () => import(`../gl_dashboards/visualizations/events_over_time.json`),
  page_views_over_time: () => import(`../gl_dashboards/visualizations/page_views_over_time.json`),
  returning_users_percentage: () =>
    import(`../gl_dashboards/visualizations/returning_users_percentage.json`),
  sessions_over_time: () => import(`../gl_dashboards/visualizations/sessions_over_time.json`),
  sessions_per_browser: () => import(`../gl_dashboards/visualizations/sessions_per_browser.json`),
  top_pages: () => import(`../gl_dashboards/visualizations/top_pages.json`),
  total_events: () => import(`../gl_dashboards/visualizations/total_events.json`),
  total_pageviews: () => import(`../gl_dashboards/visualizations/total_pageviews.json`),
  total_sessions: () => import(`../gl_dashboards/visualizations/total_sessions.json`),
  total_unique_users: () => import(`../gl_dashboards/visualizations/total_unique_users.json`),
};

const DASHBOARD_JSONS = {
  dashboard_behavior: () => import(`../gl_dashboards/dashboard_behavior.json`),
  dashboard_audience: () => import(`../gl_dashboards/dashboard_audience.json`),
};

export default {
  name: 'AnalyticsDashboard',
  components: {
    GlLoadingIcon,
    CustomizableDashboard,
  },
  data() {
    return {
      dashboard: null,
    };
  },
  async created() {
    if (DASHBOARD_JSONS[this.$route?.params.id]) {
      const dashboard = await DASHBOARD_JSONS[this.$route.params.id]();
      this.dashboard = await this.importDashboardDependencies(dashboard);
    }

    this.availableVisualizations = [];
  },
  methods: {
    // TODO: Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/382551
    async importVisualization(visualization) {
      const module = await VISUALIZATION_JSONS[visualization]();
      // Convert module to an object because widget_base.vue expects an object property.
      return { ...module };
    },
    async importDashboardDependencies(dashboard) {
      return {
        ...dashboard,
        widgets: await Promise.all(
          dashboard.widgets.map(async (widget) => ({
            ...widget,
            visualization: await this.importVisualization(widget.visualization),
          })),
        ),
      };
    },
  },
};
</script>

<template>
  <div>
    <template v-if="dashboard">
      <customizable-dashboard
        :initial-dashboard="dashboard"
        :get-visualization="importVisualization"
        :available-visualizations="availableVisualizations"
      />
    </template>
    <gl-loading-icon v-else size="lg" class="gl-my-7" />
  </div>
</template>
