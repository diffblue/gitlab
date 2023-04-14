<script>
import { GlDropdown, GlDropdownForm, GlLink, GlAlert, GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import AnalyticsClipboardInput from 'ee/product_analytics/shared/analytics_clipboard_input.vue';
import { isValidConfigFileName, configFileNameToID } from 'ee/analytics/analytics_dashboards/utils';
import { getCustomDashboards } from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import { createAlert } from '~/alert';

import LIST_OF_FEATURE_DASHBOARDS from '../gl_dashboards/analytics_dashboards.json';
import {
  I18N_DASHBOARD_LIST_TITLE,
  I18N_DASHBOARD_LIST_DESCRIPTION,
  I18N_DASHBOARD_LIST_LEARN_MORE,
  I18N_DASHBOARD_LIST_INSTRUMENTATION_DETAILS,
  I18N_DASHBOARD_LIST_SDK_HOST,
  I18N_DASHBOARD_LIST_SDK_DESCRIPTION,
  I18N_DASHBOARD_LIST_SDK_APP_ID,
  I18N_DASHBOARD_LIST_SDK_APP_ID_DESCRIPTION,
  I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER,
  I18N_ALERT_NO_POINTER_TITLE,
  I18N_ALERT_NO_POINTER_BUTTON,
  I18N_ALERT_NO_POINTER_DESCRIPTION,
} from '../constants';
import DashboardListItem from './list/dashboard_list_item.vue';

const ONBOARDING_FEATURE_COMPONENTS = {
  productAnalytics: () =>
    import('ee/product_analytics/onboarding/components/onboarding_list_item.vue'),
};

export default {
  name: 'DashboardsList',
  components: {
    GlButton,
    GlDropdown,
    GlDropdownForm,
    GlLink,
    GlAlert,
    AnalyticsClipboardInput,
    DashboardListItem,
  },
  inject: {
    showInstrumentationDetailsButton: {
      type: Boolean,
      default: true,
    },
    customDashboardsProject: {
      type: Object,
      default: null,
    },
    collectorHost: {
      type: String,
    },
    jitsuKey: {
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
  },
  async created() {
    if (this.customDashboardsProject) {
      this.loadCustomDashboards();
    }
  },
  methods: {
    featureEnabled([feature]) {
      return this.features.includes(feature);
    },
    featureRequiresOnboarding([feature]) {
      return this.requiresOnboarding.includes(feature);
    },
    routeToDashboard(dashboardId) {
      return this.$router.push(dashboardId);
    },
    redirectToProjectPointerConfig() {
      const { group, project } = document.body.dataset;
      visitUrl(
        `${gon.relative_url_root || ''}/${group}/${project}/edit#js-analytics-dashboards-settings`,
      );
    },
    async loadCustomDashboards() {
      const customFiles = await getCustomDashboards(this.customDashboardsProject);

      this.userDashboards = customFiles
        .filter(({ file_name }) => isValidConfigFileName(file_name))
        .map(({ file_name }) => configFileNameToID(file_name))
        .map((id) => ({ id, title: id }));
    },
    onboardingComplete(feature) {
      this.requiresOnboarding = this.requiresOnboarding.filter((f) => f !== feature);
      this.featureDashboards.push(...LIST_OF_FEATURE_DASHBOARDS[feature]);
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
  I18N_DASHBOARD_LIST_INSTRUMENTATION_DETAILS,
  I18N_DASHBOARD_LIST_SDK_HOST,
  I18N_DASHBOARD_LIST_SDK_DESCRIPTION,
  I18N_DASHBOARD_LIST_SDK_APP_ID,
  I18N_DASHBOARD_LIST_SDK_APP_ID_DESCRIPTION,
  I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER,
  I18N_ALERT_NO_POINTER_TITLE,
  I18N_ALERT_NO_POINTER_BUTTON,
  I18N_ALERT_NO_POINTER_DESCRIPTION,
  helpPageUrl: helpPagePath('user/product_analytics/index', {
    anchor: 'product-analytics-dashboards',
  }),
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
      <div>
        <gl-button to="visualization-designer" data-testid="visualization-designer-button">
          {{ $options.I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER }}
        </gl-button>
        <gl-dropdown
          v-if="showInstrumentationDetailsButton"
          class="gl-my-6"
          data-testid="intrumentation-details-dropdown"
          :text="$options.I18N_DASHBOARD_LIST_INSTRUMENTATION_DETAILS"
          split-to="setup"
          split
          right
        >
          <gl-dropdown-form class="gl-px-4! gl-py-2!">
            <analytics-clipboard-input
              class="gl-mb-6 gl-w-full"
              :label="$options.I18N_DASHBOARD_LIST_SDK_HOST"
              :description="$options.I18N_DASHBOARD_LIST_SDK_DESCRIPTION"
              :value="collectorHost"
            />

            <analytics-clipboard-input
              class="gl-w-full"
              :label="$options.I18N_DASHBOARD_LIST_SDK_APP_ID"
              :description="$options.I18N_DASHBOARD_LIST_SDK_APP_ID_DESCRIPTION"
              :value="jitsuKey"
            />
          </gl-dropdown-form>
        </gl-dropdown>
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
        :key="dashboard.id"
        :dashboard="dashboard"
      />
    </ul>
  </div>
</template>
