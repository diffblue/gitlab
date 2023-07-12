<script>
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_CREATED,
  HTTP_STATUS_NOT_FOUND,
} from '~/lib/utils/http_status';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import {
  buildDefaultDashboardFilters,
  getDashboardConfig,
  updateApolloCache,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import { configFileNameToID, isValidConfigFileName } from 'ee/analytics/analytics_dashboards/utils';
import {
  getCustomDashboard,
  getProductAnalyticsVisualization,
  getProductAnalyticsVisualizationList,
  saveCustomDashboard,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { builtinDashboards, builtinVisualizations } from '../gl_dashboards';
import {
  I18N_DASHBOARD_ERROR_WHILE_SAVING,
  I18N_DASHBOARD_NOT_FOUND_ACTION,
  I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
  I18N_DASHBOARD_NOT_FOUND_TITLE,
  I18N_DASHBOARD_SAVED_SUCCESSFULLY,
  I18N_PRODUCT_ANALYTICS_TITLE,
  NEW_DASHBOARD,
  VISUALIZATION_TYPE_FILE,
} from '../constants';
import getProductAnalyticsDashboardQuery from '../graphql/queries/get_product_analytics_dashboard.query.graphql';
import getAvailableVisualizations from '../graphql/queries/get_all_product_analytics_visualizations.query.graphql';

export default {
  name: 'AnalyticsDashboard',
  components: {
    GlLoadingIcon,
    CustomizableDashboard,
    GlEmptyState,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    customDashboardsProject: {
      type: Object,
      default: null,
    },
    projectFullPath: {
      type: String,
    },
    projectId: {
      type: String,
    },
    dashboardEmptyStateIllustrationPath: {
      type: String,
    },
    breadcrumbState: {
      type: Object,
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
      initialDashboard: null,
      showEmptyState: false,
      availableVisualizations: {
        [I18N_PRODUCT_ANALYTICS_TITLE]: {
          loading: true,
          visualizations: [],
        },
      },
      defaultFilters: this.isNewDashboard
        ? {}
        : buildDefaultDashboardFilters(window.location.search),
      isSaving: false,
      backUrl: this.$router.resolve('/').href,
      editingEnabled: this.glFeatures.combinedAnalyticsDashboardsEditor,
      jitsuEnabled: !this.glFeatures.productAnalyticsSnowplowSupport,
    };
  },
  async created() {
    // Only allow new dashboards when the dashboards editor is enabled
    if (this.editingEnabled && this.isNewDashboard) {
      this.initialDashboard = this.createNewDashboard();
      return;
    }

    let loadedDashboard;

    // Only check Jitsu dashboards when Jitsu is enabled and this isn't a new
    // dashboard request
    if (this.jitsuEnabled && !this.isNewDashboard) {
      if (builtinDashboards[this.$route?.params.slug]) {
        loadedDashboard = await this.loadBuiltInDashboard(this.$route?.params.slug);
      } else if (this.customDashboardsProject) {
        loadedDashboard = await this.loadCustomDashboard();
      }
    }

    // If we've got a new dashboard prepped or we found a Jitsu dashboard render it
    // Otherwise, show the empty state if Jitsu is enabled and we couldn't find it
    // Or we couldn't prep the new dashboard because the dashboard editor is disabled
    if (loadedDashboard) {
      this.initialDashboard = await this.importDashboardDependencies(loadedDashboard);
      await this.loadAvailableVisualizations();
    } else if (this.jitsuEnabled || this.isNewDashboard) {
      this.showEmptyState = true;
    }
  },
  beforeDestroy() {
    // Clear the breadcrumb name when we leave this component so it doesn't
    // flash the wrong name when a user views a different dashboard
    this.breadcrumbState.updateName('');
  },
  apollo: {
    initialDashboard: {
      query: getProductAnalyticsDashboardQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          slug: this.$route?.params.slug,
        };
      },
      skip() {
        return this.jitsuEnabled || this.isNewDashboard;
      },
      update(data) {
        const dashboard = data?.project?.productAnalyticsDashboards?.nodes[0];

        if (!dashboard) {
          this.showEmptyState = true;
          return null;
        }

        const panels = (dashboard.panels?.nodes || []).map((panel, index) => ({
          ...panel,
          id: index + 1,
        }));

        return {
          ...dashboard,
          panels,
        };
      },
      result() {
        this.breadcrumbState.updateName(this.initialDashboard?.title || '');
      },
      error(error) {
        // TODO: Show user friendly errors when request fails
        // https://gitlab.com/gitlab-org/gitlab/-/issues/395788
        throw error;
      },
    },
    availableVisualizations: {
      query: getAvailableVisualizations,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      skip() {
        return (
          !this.editingEnabled ||
          this.jitsuEnabled ||
          !this.initialDashboard ||
          !this.initialDashboard?.userDefined
        );
      },
      update(data) {
        const visualizations = data?.project?.productAnalyticsVisualizations?.nodes;
        return {
          ...this.availableVisualizations,
          [I18N_PRODUCT_ANALYTICS_TITLE]: {
            loading: false,
            visualizations,
          },
        };
      },
      error(error) {
        // TODO: Show user friendly errors when request fails
        // https://gitlab.com/gitlab-org/gitlab/-/issues/395788
        throw error;
      },
    },
  },
  methods: {
    createNewDashboard() {
      return NEW_DASHBOARD();
    },
    async loadBuiltInDashboard() {
      const builtInDashboard = await builtinDashboards[this.$route.params.slug]();
      return { ...builtInDashboard, builtin: true };
    },
    async loadCustomDashboard() {
      try {
        const customDashboard = await getCustomDashboard(
          this.$route?.params.slug,
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
    async getCustomVisualizationIds() {
      const visualizationFiles = await getProductAnalyticsVisualizationList(
        this.customDashboardsProject,
      );

      return visualizationFiles
        .filter(({ file_name }) => isValidConfigFileName(file_name))
        .map(({ file_name }) => configFileNameToID(file_name));
    },
    async loadAvailableVisualizations() {
      const builtInVisualizationIds = Object.keys(builtinVisualizations).map((id) => id);
      const customVisualizationIds = this.customDashboardsProject
        ? await this.getCustomVisualizationIds()
        : [];

      this.availableVisualizations[I18N_PRODUCT_ANALYTICS_TITLE] = {
        loading: false,
        visualizationIds: [...builtInVisualizationIds, ...customVisualizationIds],
      };
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
                visualization: {
                  slug: panel.visualization,
                  ...(await this.importVisualization(panel.visualization, panel.visualizationType)),
                },
              })),
            )
          : [],
      };
    },
    async saveDashboard(dashboardSlug, dashboard) {
      try {
        this.isSaving = true;
        const saveResult = await saveCustomDashboard({
          dashboardSlug,
          dashboardConfig: getDashboardConfig(dashboard),
          projectInfo: this.customDashboardsProject,
          isNewFile: this.isNewDashboard,
        });

        if (saveResult?.status === HTTP_STATUS_CREATED) {
          this.$toast.show(I18N_DASHBOARD_SAVED_SUCCESSFULLY);

          const client = this.$apollo.getClient();
          updateApolloCache(client, this.projectId, dashboardSlug, dashboard);

          if (this.isNewDashboard) {
            // We redirect now to the new route
            this.$router.push({
              name: 'dashboard-detail',
              params: { slug: dashboardSlug },
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
    <customizable-dashboard
      v-if="initialDashboard"
      :initial-dashboard="initialDashboard"
      :get-visualization="importVisualization"
      :available-visualizations="availableVisualizations"
      :default-filters="defaultFilters"
      :is-saving="isSaving"
      :date-range-limit="0"
      :sync-url-filters="!isNewDashboard"
      :is-new-dashboard="isNewDashboard"
      show-date-range-filter
      @save="saveDashboard"
    />
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
