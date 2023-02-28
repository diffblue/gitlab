<script>
import { GlDropdown, GlDropdownForm, GlLink, GlAvatar, GlIcon, GlLabel } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import AnalyticsClipboardInput from 'ee/product_analytics/shared/analytics_clipboard_input.vue';
import LIST_OF_DASHBOARDS from '../gl_dashboards/analytics_dashboards.json';
import {
  I18N_DASHBOARD_LIST_TITLE,
  I18N_DASHBOARD_LIST_DESCRIPTION,
  I18N_DASHBOARD_LIST_LEARN_MORE,
  I18N_DASHBOARD_LIST_INSTRUMENTATION_DETAILS,
  I18N_DASHBOARD_LIST_SDK_HOST,
  I18N_DASHBOARD_LIST_SDK_DESCRIPTION,
  I18N_DASHBOARD_LIST_SDK_APP_ID,
  I18N_DASHBOARD_LIST_SDK_APP_ID_DESCRIPTION,
} from '../constants';

export default {
  name: 'DashboardsList',
  components: {
    GlDropdown,
    GlDropdownForm,
    GlAvatar,
    GlIcon,
    GlLabel,
    GlLink,
    AnalyticsClipboardInput,
  },
  inject: {
    showInstrumentationDetailsButton: {
      type: Boolean,
      default: true,
    },
    collectorHost: {
      type: String,
    },
    jitsuKey: {
      type: String,
    },
    features: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    availableDashboards() {
      return Object.entries(LIST_OF_DASHBOARDS).reduce(
        (enabledDashboards, [feature, featureDashboards]) => {
          if (this.featureEnabled(feature)) {
            return { ...enabledDashboards, ...featureDashboards };
          }

          return enabledDashboards;
        },
        {},
      );
    },
  },
  methods: {
    featureEnabled(feature) {
      return this.features[feature];
    },
    routeToDashboard(dashboardId) {
      return this.$router.push(dashboardId);
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
  helpPageUrl: helpPagePath('user/product_analytics/index', {
    anchor: 'product-analytics-dashboards',
  }),
};
</script>

<template>
  <div>
    <header class="gl-display-flex gl-justify-content-space-between gl-align-items-flex-start">
      <div>
        <h2 data-testid="title">{{ $options.I18N_DASHBOARD_LIST_TITLE }}</h2>
        <p data-testid="description">
          {{ $options.I18N_DASHBOARD_LIST_DESCRIPTION }}
          <gl-link data-testid="help-link" :href="$options.helpPageUrl">{{
            $options.I18N_DASHBOARD_LIST_LEARN_MORE
          }}</gl-link>
        </p>
      </div>
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
    </header>
    <ul class="content-list gl-border-t gl-border-gray-50">
      <li
        v-for="dashboard in availableDashboards"
        :key="dashboard.id"
        data-testid="dashboard-list-item"
        class="gl-display-flex! gl-px-5! gl-align-items-center gl-hover-cursor-pointer gl-hover-bg-blue-50"
        @click="routeToDashboard(dashboard.id)"
      >
        <div class="gl-float-left gl-mr-4 gl-display-flex gl-align-items-center">
          <gl-icon
            data-testid="dashboard-icon"
            name="project"
            class="gl-text-gray-200 gl-mr-3"
            :size="16"
          />
          <gl-avatar :entity-name="dashboard.title" shape="rect" :size="32" />
        </div>
        <div
          class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-flex-grow-1"
        >
          <div class="gl-display-flex gl-flex-direction-column">
            <router-link
              data-testid="dashboard-link"
              class="gl-font-weight-bold gl-line-height-normal"
              :to="dashboard.id"
              >{{ dashboard.title }}</router-link
            >
            <p
              data-testid="dashboard-description"
              class="gl-line-height-normal gl-m-0 gl-text-gray-500"
            >
              {{ dashboard.description }}
            </p>
          </div>
          <div class="gl-float-right">
            <gl-label
              v-for="label in dashboard.labels"
              :key="label"
              :title="label"
              data-testid="dashboard-label"
              background-color="#D9C2EE"
            />
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
