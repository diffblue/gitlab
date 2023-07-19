<script>
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_CREATED } from '~/lib/utils/http_status';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import {
  buildDefaultDashboardFilters,
  getDashboardConfig,
  updateApolloCache,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import { saveCustomDashboard } from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  I18N_DASHBOARD_ERROR_WHILE_SAVING,
  I18N_DASHBOARD_NOT_FOUND_ACTION,
  I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
  I18N_DASHBOARD_NOT_FOUND_TITLE,
  I18N_DASHBOARD_SAVED_SUCCESSFULLY,
  I18N_PRODUCT_ANALYTICS_TITLE,
  NEW_DASHBOARD,
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
    namespaceFullPath: {
      type: String,
    },
    namespaceId: {
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
      alert: null,
    };
  },
  async created() {
    if (!this.isNewDashboard) {
      return;
    }

    if (this.editingEnabled) {
      this.initialDashboard = this.createNewDashboard();
      return;
    }

    this.showEmptyState = true;
  },
  beforeDestroy() {
    this.alert?.dismiss();

    // Clear the breadcrumb name when we leave this component so it doesn't
    // flash the wrong name when a user views a different dashboard
    this.breadcrumbState.updateName('');
  },
  apollo: {
    initialDashboard: {
      query: getProductAnalyticsDashboardQuery,
      variables() {
        return {
          projectPath: this.namespaceFullPath,
          slug: this.$route?.params.slug,
        };
      },
      skip() {
        return this.isNewDashboard;
      },
      update(data) {
        const dashboard = data?.project?.productAnalyticsDashboards?.nodes[0];

        if (!dashboard) {
          this.showEmptyState = true;
          return null;
        }

        return {
          ...dashboard,
          panels: dashboard.panels?.nodes || [],
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
          projectPath: this.namespaceFullPath,
        };
      },
      skip() {
        return (
          !this.editingEnabled || !this.initialDashboard || !this.initialDashboard?.userDefined
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
          this.alert?.dismiss();

          this.$toast.show(I18N_DASHBOARD_SAVED_SUCCESSFULLY);

          const client = this.$apollo.getClient();
          updateApolloCache(client, this.namespaceId, dashboardSlug, dashboard);

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
          this.alert = createAlert({
            message: error.response?.data?.message || I18N_DASHBOARD_ERROR_WHILE_SAVING,
          });
        } else {
          this.alert = createAlert({
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
