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
import { inbuiltDashboards, inbuiltVisualizations } from '../gl_dashboards';
import { VISUALIZATION_TYPE_FILE } from '../constants';

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

    if (inbuiltDashboards[this.$route?.params.id]) {
      // Getting a GitLab pre-defined dashboard
      loadedDashboard = await inbuiltDashboards[this.$route.params.id]();
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

    await this.loadAvailableVisualizations();
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

      if (isFileVisualization && inbuiltVisualizations[visualization]) {
        const module = await inbuiltVisualizations[visualization]();
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
