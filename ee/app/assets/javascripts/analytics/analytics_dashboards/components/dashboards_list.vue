<script>
import { GlLink, GlAlert, GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  PRODUCT_ANALYTICS_FEATURE_DASHBOARDS,
  I18N_DASHBOARD_LIST_TITLE,
  I18N_DASHBOARD_LIST_DESCRIPTION,
  I18N_DASHBOARD_LIST_LEARN_MORE,
  I18N_DASHBOARD_LIST_NEW_DASHBOARD,
  I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER,
  I18N_ALERT_NO_POINTER_TITLE,
  I18N_ALERT_NO_POINTER_BUTTON,
  I18N_ALERT_NO_POINTER_DESCRIPTION,
  FEATURE_PRODUCT_ANALYTICS,
} from '../constants';
import getAllProductAnalyticsDashboardsQuery from '../graphql/queries/get_all_product_analytics_dashboards.query.graphql';
import DashboardListItem from './list/dashboard_list_item.vue';

const ONBOARDING_FEATURE_COMPONENTS = {
  productAnalytics: () =>
    import('ee/product_analytics/onboarding/components/onboarding_list_item.vue'),
};

export default {
  name: 'DashboardsList',
  components: {
    GlButton,
    GlLink,
    GlAlert,
    DashboardListItem,
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
    collectorHost: {
      type: String,
    },
    trackingKey: {
      type: String,
    },
    features: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      requiresOnboarding: Object.keys(ONBOARDING_FEATURE_COMPONENTS),
      featureDashboards: [],
      userDashboards: [],
      showCreateButtons: this.glFeatures.combinedAnalyticsDashboardsEditor,
    };
  },
  computed: {
    dashboards() {
      return [...this.featureDashboards, ...this.userDashboards];
    },
    activeOnboardingComponents() {
      return Object.fromEntries(
        Object.entries(ONBOARDING_FEATURE_COMPONENTS)
          .filter(this.featureEnabled)
          .filter(this.featureRequiresOnboarding),
      );
    },
    unavailableFeatures() {
      return this.features.filter(this.featureDisabled).filter(this.featureRequiresOnboarding);
    },
  },
  apollo: {
    userDashboards: {
      // TODO: Rename once the type is updated to be just AnalyticsDashboards
      // https://gitlab.com/gitlab-org/gitlab/-/issues/412290
      query: getAllProductAnalyticsDashboardsQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      update(data) {
        return data?.project?.productAnalyticsDashboards?.nodes
          .map((dashboard) => {
            // TODO: Simplify checks when backend returns dashboards only for onboarded features
            // https://gitlab.com/gitlab-org/gitlab/-/issues/411608
            if (
              !dashboard.userDefined &&
              this.unavailableFeatures.includes(FEATURE_PRODUCT_ANALYTICS) &&
              PRODUCT_ANALYTICS_FEATURE_DASHBOARDS.includes(dashboard.slug)
            ) {
              return null;
            }

            return dashboard;
          })
          .filter(Boolean);
      },
      // TODO: Remove when backend returns dashboards only for onboarded features
      // https://gitlab.com/gitlab-org/gitlab/-/issues/411608
      skip() {
        return this.featureRequiresOnboarding([FEATURE_PRODUCT_ANALYTICS]);
      },
      error(err) {
        this.onError(err);
      },
    },
  },
  methods: {
    featureEnabled([feature]) {
      return this.features.includes(feature);
    },
    featureDisabled([feature]) {
      return !this.features.includes(feature);
    },
    featureRequiresOnboarding([feature]) {
      return this.requiresOnboarding.includes(feature);
    },
    routeToDashboard(dashboardId) {
      return this.$router.push(dashboardId);
    },
    redirectToProjectPointerConfig() {
      visitUrl(
        `${gon.relative_url_root || ''}/${
          this.projectFullPath
        }/edit#js-analytics-dashboards-settings`,
      );
    },
    onboardingComplete(feature) {
      this.requiresOnboarding = this.requiresOnboarding.filter((f) => f !== feature);
    },
    onError(error, captureError = true, message = '') {
      createAlert({
        message: message || error.message,
        captureError,
        error,
      });
    },
  },
  I18N_DASHBOARD_LIST_TITLE,
  I18N_DASHBOARD_LIST_DESCRIPTION,
  I18N_DASHBOARD_LIST_LEARN_MORE,
  I18N_DASHBOARD_LIST_NEW_DASHBOARD,
  I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER,
  I18N_ALERT_NO_POINTER_TITLE,
  I18N_ALERT_NO_POINTER_BUTTON,
  I18N_ALERT_NO_POINTER_DESCRIPTION,
  helpPageUrl: helpPagePath('user/analytics/analytics_dashboards'),
};
</script>

<template>
  <div>
    <header
      class="gl-display-flex gl-justify-content-space-between gl-lg-flex-direction-row gl-flex-direction-column gl-align-items-flex-start gl-my-6"
    >
      <div>
        <h2 class="gl-mt-0" data-testid="title">{{ $options.I18N_DASHBOARD_LIST_TITLE }}</h2>
        <p data-testid="description">
          {{ $options.I18N_DASHBOARD_LIST_DESCRIPTION }}
          <gl-link data-testid="help-link" :href="$options.helpPageUrl">{{
            $options.I18N_DASHBOARD_LIST_LEARN_MORE
          }}</gl-link>
        </p>
      </div>
      <div v-if="showCreateButtons">
        <gl-button to="visualization-designer" data-testid="visualization-designer-button">
          {{ $options.I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER }}
        </gl-button>
        <router-link
          v-if="customDashboardsProject"
          to="/new"
          class="btn btn-confirm btn-md gl-button"
          data-testid="new-dashboard-button"
        >
          {{ $options.I18N_DASHBOARD_LIST_NEW_DASHBOARD }}
        </router-link>
      </div>
    </header>
    <gl-alert
      v-if="!customDashboardsProject"
      :dismissible="false"
      :primary-button-text="$options.I18N_ALERT_NO_POINTER_BUTTON"
      :title="$options.I18N_ALERT_NO_POINTER_TITLE"
      class="gl-mt-3 gl-mb-6"
      @primaryAction="redirectToProjectPointerConfig"
      >{{ $options.I18N_ALERT_NO_POINTER_DESCRIPTION }}</gl-alert
    >
    <ul class="content-list gl-border-t gl-border-gray-50">
      <component
        :is="setupComponent"
        v-for="(setupComponent, feature) in activeOnboardingComponents"
        :key="feature"
        @complete="onboardingComplete(feature)"
        @error="onError"
      />

      <dashboard-list-item
        v-for="dashboard in dashboards"
        :key="dashboard.slug"
        :dashboard="dashboard"
      />
    </ul>
  </div>
</template>
