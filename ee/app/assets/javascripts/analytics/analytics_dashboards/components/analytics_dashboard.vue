<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { createAlert } from '~/alert';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_BAD_REQUEST,
} from '~/lib/utils/http_status';
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
  I18N_DASHBOARD_SAVED_SUCCESSFULLY,
  I18N_DASHBOARD_ERROR_WHILE_SAVING,
  NEW_DASHBOARD,
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
  props: {
    isNewDashboard: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dashboard: null,
      showEmptyState: false,
      availableVisualizations: [],
      defaultFilters: this.isNewDashboard
        ? {}
        : buildDefaultDashboardFilters(window.location.search),
      isSaving: false,
      backUrl: this.$router.resolve('/').href,
    };
  },
  async created() {
    let loadedDashboard;

    if (this.isNewDashboard) {
      loadedDashboard = await this.createNewDashboard();
    } else if (builtinDashboards[this.$route?.params.id]) {
      loadedDashboard = await this.loadBuiltInDashboard(this.$route?.params.id);
    } else if (this.customDashboardsProject) {
      loadedDashboard = await this.loadCustomDashboard();
    }

    if (loadedDashboard) {
      this.dashboard = await this.importDashboardDependencies(loadedDashboard);
      this.loadAvailableVisualizations();
    } else {
      this.showEmptyState = true;
    }
  },
  methods: {
    async createNewDashboard() {
      return { ...NEW_DASHBOARD, default: { ...NEW_DASHBOARD } };
    },
    async loadBuiltInDashboard() {
      const builtInDashboard = await builtinDashboards[this.$route.params.id]();
      return { ...builtInDashboard, builtin: true };
    },
    async loadCustomDashboard() {
      try {
        const customDashboard = await getCustomDashboard(
          this.$route?.params.id,
          this.customDashboardsProject,
        );
        return { ...customDashboard, default: { ...customDashboard } };
      } catch (error) {
        if (error?.response?.status === HTTP_STATUS_NOT_FOUND) {
          return null;
        }
        // TODO: Show user friendly errors when request fails
        // https://gitlab.com/gitlab-org/gitlab/-/issues/395788
        throw error;
      }
    },
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
    async saveDashboard(dashboardId, dashboardObject) {
      try {
        this.isSaving = true;
        const saveResult = await saveCustomDashboard({
          dashboardId,
          dashboardObject,
          projectInfo: this.customDashboardsProject,
          isNewFile: this.isNewDashboard,
        });

        if (saveResult?.status === HTTP_STATUS_CREATED) {
          this.$toast.show(I18N_DASHBOARD_SAVED_SUCCESSFULLY);

          if (this.isNewDashboard) {
            // We redirect now to the new route
            this.$router.push({
              name: 'dashboard-detail',
              params: { id: dashboardId },
            });
          }
        } else {
          throw new Error(`Bad save dashboard response. Status:${saveResult?.status}`);
        }
      } catch (error) {
        if (error.response?.status === HTTP_STATUS_BAD_REQUEST) {
          // We can assume bad request errors are a result of user error.
          // We don't need to capture these errors and can render the message to the user.
          createAlert({
            message: error.response?.data?.message || I18N_DASHBOARD_ERROR_WHILE_SAVING,
          });
        } else {
          createAlert({
            message: I18N_DASHBOARD_ERROR_WHILE_SAVING,
            error,
            captureError: true,
          });
        }
      } finally {
        this.isSaving = false;
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
        :show-date-range-filter="!isNewDashboard"
        :sync-url-filters="!isNewDashboard"
        :is-new-dashboard="isNewDashboard"
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
