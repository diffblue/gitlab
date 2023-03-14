<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { HTTP_STATUS_CREATED, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
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
import {
  VISUALIZATION_TYPE_FILE,
  I18N_DASHBOARD_NOT_FOUND_TITLE,
  I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
  I18N_DASHBOARD_NOT_FOUND_ACTION,
} from '../constants';

export default {
  name: 'AnalyticsDashboard',
  components: {
    GlLoadingIcon,
    CustomizableDashboard,
    GlEmptyState,
  },
  inject: {
    customDashboardsProject: {
      type: Object,
      default: null,
    },
    dashboardEmptyStateIllustrationPath: {
      type: String,
    },
  },
  data() {
    return {
      dashboard: null,
      showEmptyState: false,
      availableVisualizations: [],
      defaultFilters: buildDefaultDashboardFilters(window.location.search),
      isSaving: false,
      backUrl: this.$router.resolve('/').href,
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
      try {
        loadedDashboard = await getCustomDashboard(
          this.$route?.params.id,
          this.customDashboardsProject,
        );
      } catch (error) {
        if (error?.response?.status === HTTP_STATUS_NOT_FOUND) {
          this.showEmptyState = true;
          return;
        }
        // TODO: Show user friendly errors when request fails
        // https://gitlab.com/gitlab-org/gitlab/-/issues/395788
        throw error;
      }

      loadedDashboard.default = { ...loadedDashboard };
      this.dashboard = await this.importDashboardDependencies(loadedDashboard);
    } else {
      this.showEmptyState = true;
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
  i18n: {
    emptyTitle: I18N_DASHBOARD_NOT_FOUND_TITLE,
    emptyDescription: I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
    emptyAction: I18N_DASHBOARD_NOT_FOUND_ACTION,
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
    <gl-empty-state
      v-else-if="showEmptyState"
      :svg-path="dashboardEmptyStateIllustrationPath"
      :title="$options.i18n.emptyTitle"
      :description="$options.i18n.emptyDescription"
      :primary-button-text="$options.i18n.emptyAction"
      :primary-button-link="backUrl"
    />
    <gl-loading-icon v-else size="lg" class="gl-my-7" />
  </div>
</template>
