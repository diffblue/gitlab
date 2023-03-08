<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { HTTP_STATUS_CREATED } from '~/lib/utils/http_status';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { buildDefaultDashboardFilters } from 'ee/vue_shared/components/customizable_dashboard/utils';
import { isValidConfigFileName, configFileNameToID } from 'ee/analytics/analytics_dashboards/utils';
import {
  getCustomDashboard,
  getProductAnalyticsVisualizationList,
  getProductAnalyticsVisualization,
  saveCustomDashboard,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import { builtinDashboards, builtinVisualizations } from '../gl_dashboards';
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
      isSaving: false,
    };
  },
  async created() {
    let loadedDashboard;

    if (builtinDashboards[this.$route?.params.id]) {
      // Getting a GitLab pre-defined dashboard
      loadedDashboard = await builtinDashboards[this.$route.params.id]();
      loadedDashboard.builtin = true;
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

      if (isFileVisualization && builtinVisualizations[visualization]) {
        const module = await builtinVisualizations[visualization]();
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
    async saveDashboard(dashboardId, dashboardCode) {
      try {
        this.isSaving = true;
        const saveResult = await saveCustomDashboard(
          dashboardId,
          dashboardCode,
          this.customDashboardsProject,
        );
        if (saveResult?.status === HTTP_STATUS_CREATED) {
          this.$toast.show(s__('Analytics|Dashboard was saved successfully'));
        } else {
          createAlert({
            message: s__('Analytics|Error while saving Dashboard!'),
          });
        }
        this.isSaving = false;
      } catch (error) {
        this.isSaving = false;
        createAlert({
          message: s__('Analytics|Error while saving Dashboard!'),
          error,
          reportError: true,
        });
      }
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
        :is-saving="isSaving"
        :date-range-limit="0"
        show-date-range-filter
        sync-url-filters
        @save="saveDashboard"
      />
    </template>
    <gl-loading-icon v-else size="lg" class="gl-my-7" />
  </div>
</template>
