<script>
import { GlEmptyState, GlSkeletonLoader } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_CREATED } from '~/lib/utils/http_status';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import {
  buildDefaultDashboardFilters,
  getDashboardConfig,
  updateApolloCache,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import { saveCustomDashboard } from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { NEW_DASHBOARD } from '../constants';
import getProductAnalyticsDashboardQuery from '../graphql/queries/get_product_analytics_dashboard.query.graphql';
import getAvailableVisualizations from '../graphql/queries/get_all_product_analytics_visualizations.query.graphql';

const BUILT_IN_VALUE_STREAM_DASHBOARD = 'value_stream_dashboard';
const HIDE_DATE_RANGE_FILTER = [BUILT_IN_VALUE_STREAM_DASHBOARD];

export default {
  name: 'AnalyticsDashboard',
  components: {
    CustomizableDashboard,
    GlEmptyState,
    GlSkeletonLoader,
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
        loading: true,
        visualizations: [],
      },
      defaultFilters: buildDefaultDashboardFilters(window.location.search),
      isSaving: false,
      backUrl: this.$router.resolve('/').href,
      editingEnabled: this.glFeatures.combinedAnalyticsDashboardsEditor,
      changesSaved: false,
      alert: null,
      hasDashboardError: false,
    };
  },
  computed: {
    showDateRangeFilter() {
      return !HIDE_DATE_RANGE_FILTER.includes(this.initialDashboard?.slug);
    },
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
        const dashboard = data?.project?.customizableDashboards?.nodes[0];

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
        this.showError({
          error,
          capture: true,
          message: s__(
            'Analytics|Something went wrong while loading the dashboard. Refresh the page to try again or see %{linkStart}troubleshooting documentation%{linkEnd}.',
          ),
          messageLinks: {
            link: helpPagePath('user/analytics/analytics_dashboards', {
              anchor: '#troubleshooting',
            }),
          },
        });
        this.hasDashboardError = true;
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
        const visualizations = data?.project?.customizableDashboardVisualizations?.nodes;
        return {
          loading: false,
          visualizations,
        };
      },
      error(error) {
        // TODO: Show user friendly errors when request fails
        // https://gitlab.com/gitlab-org/gitlab/-/issues/425119
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
        this.changesSaved = false;
        this.isSaving = true;
        const saveResult = await saveCustomDashboard({
          dashboardSlug,
          dashboardConfig: getDashboardConfig(dashboard),
          projectInfo: this.customDashboardsProject,
          isNewFile: this.isNewDashboard,
        });

        if (saveResult?.status === HTTP_STATUS_CREATED) {
          this.alert?.dismiss();

          this.$toast.show(s__('Analytics|Dashboard was saved successfully'));

          const client = this.$apollo.getClient();
          updateApolloCache(
            client,
            this.namespaceId,
            dashboardSlug,
            dashboard,
            this.namespaceFullPath,
          );

          if (this.isNewDashboard) {
            // We redirect now to the new route
            this.$router.push({
              name: 'dashboard-detail',
              params: { slug: dashboardSlug },
            });
          }

          this.changesSaved = true;
        } else {
          throw new Error(`Bad save dashboard response. Status:${saveResult?.status}`);
        }
      } catch (error) {
        if (error.response?.status === HTTP_STATUS_BAD_REQUEST) {
          // We can assume bad request errors are a result of user error.
          // We don't need to capture these errors and can render the message to the user.
          this.showError({ error, capture: false, message: error.response?.data?.message });
        } else {
          this.showError({ error, capture: true });
        }
      } finally {
        this.isSaving = false;
      }
    },
    showError({ error, capture, message, messageLinks }) {
      this.alert = createAlert({
        message: message || s__('Analytics|Error while saving dashboard'),
        messageLinks,
        error,
        captureError: capture,
      });
    },
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
      :show-date-range-filter="showDateRangeFilter"
      :changes-saved="changesSaved"
      @save="saveDashboard"
    />
    <gl-empty-state
      v-else-if="showEmptyState"
      :svg-path="dashboardEmptyStateIllustrationPath"
      :title="s__('Analytics|Dashboard not found')"
      :description="s__('Analytics|No dashboard matches the specified URL path.')"
      :primary-button-text="s__('Analytics|View available dashboards')"
      :primary-button-link="backUrl"
    />
    <div v-else-if="!hasDashboardError" class="gl-mt-7">
      <gl-skeleton-loader />
    </div>
  </div>
</template>
