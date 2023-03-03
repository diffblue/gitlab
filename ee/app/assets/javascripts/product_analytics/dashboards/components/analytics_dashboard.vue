<script>
import { GlLoadingIcon } from '@gitlab/ui';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { buildDefaultDashboardFilters } from 'ee/vue_shared/components/customizable_dashboard/utils';

import { isValidConfigFileName, configFileNameToID } from 'ee/analytics/analytics_dashboards/utils';
import {
  getCustomDashboard,
  getProductAnalyticsVisualizationList,
  getProductAnalyticsVisualization,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';

import { VISUALIZATION_TYPE_FILE } from '../constants';

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
  inject: {
    customDashboardsProject: {
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      dashboard: null,
      availableVisualizations: [],
      defaultFilters: buildDefaultDashboardFilters(window.location.search),
    };
  },
  async created() {
    let loadedDashboard;

    if (DASHBOARD_JSONS[this.$route?.params.id]) {
      // Getting a GitLab pre-defined dashboard
      loadedDashboard = await DASHBOARD_JSONS[this.$route.params.id]();
      this.dashboard = await this.importDashboardDependencies(loadedDashboard);
    } else if (this.customDashboardsProject) {
      // Load custom dashboard from file
      loadedDashboard = await getCustomDashboard(
        this.$route?.params.id,
        this.customDashboardsProject,
      );
      loadedDashboard.default = { ...loadedDashboard };
      this.dashboard = await this.importDashboardDependencies(loadedDashboard);
    } else {
      return;
    }

    this.loadAvailableVisualizations();
  },
  methods: {
    async loadAvailableVisualizations() {
      // Loading all visualizations from file
      this.availableVisualizations = [];

      if (this.customDashboardsProject) {
        const visualizations = await getProductAnalyticsVisualizationList(
          this.customDashboardsProject,
        );

        for (const visualization of visualizations) {
          const fileName = visualization.file_name;
          if (isValidConfigFileName(fileName)) {
            const id = configFileNameToID(fileName);

            this.availableVisualizations.push({
              id,
              name: id,
            });
          }
        }
      }
    },
    // TODO: Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/382551
    async importVisualization(visualization, visualizationType) {
      const isFileVisualization =
        visualizationType === VISUALIZATION_TYPE_FILE || visualizationType === undefined;

      if (isFileVisualization && VISUALIZATION_JSONS[visualization]) {
        const module = await VISUALIZATION_JSONS[visualization]();
        return { ...module };
      }

      if (isFileVisualization) {
        const file = await getProductAnalyticsVisualization(
          visualization,
          this.customDashboardsProject,
        );
        return { ...file };
      }

      return visualization;
    },
    async importDashboardDependencies(dashboard) {
      return {
        ...dashboard,
        panels: dashboard.panels
          ? await Promise.all(
              dashboard.panels.map(async (panel) => ({
                ...panel,
                visualization: await this.importVisualization(
                  panel.visualization,
                  panel.visualizationType,
                ),
              })),
            )
          : [],
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
        :default-filters="defaultFilters"
        show-date-range-filter
        sync-url-filters
      />
    </template>
    <gl-loading-icon v-else size="lg" class="gl-my-7" />
  </div>
</template>
