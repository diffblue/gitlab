<script>
import { GlDropdown, GlDropdownForm, GlLink, GlAvatar, GlIcon, GlLabel } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import AnalyticsClipboardInput from '../../shared/analytics_clipboard_input.vue';
import jsonList from '../gl_dashboards/analytics_dashboards.json';
import { I18N_DASHBOARD_LIST } from '../constants';

export default {
  name: 'AnalyticsDashboard',
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
    jitsuHost: {
      type: String,
    },
    jitsuProjectId: {
      type: String,
    },
  },
  data() {
    return {
      dashboards: jsonList.internalDashboards,
    };
  },
  methods: {
    routeToDashboard(dashboardId) {
      return this.$router.push(dashboardId);
    },
  },
  i18n: I18N_DASHBOARD_LIST,
  helpPageUrl: helpPagePath('user/product_analytics/index', {
    anchor: 'product-analytics-dashboards',
  }),
};
</script>

<template>
  <div>
    <header class="gl-display-flex gl-justify-content-space-between gl-align-items-flex-start">
      <div>
        <h2 data-testid="title">{{ $options.i18n.title }}</h2>
        <p data-testid="description">
          {{ $options.i18n.description }}
          <gl-link data-testid="help-link" :href="$options.helpPageUrl">{{
            $options.i18n.learnMore
          }}</gl-link>
        </p>
      </div>
      <gl-dropdown
        class="gl-my-6"
        data-testid="intrumentation-details-dropdown"
        :text="$options.i18n.instrumentationDetails"
        split-to="setup"
        split
        right
      >
        <gl-dropdown-form class="gl-px-4! gl-py-2!">
          <analytics-clipboard-input
            class="gl-mb-6 gl-w-full"
            :label="$options.i18n.sdkHost"
            :description="$options.i18n.sdkHostDescription"
            :value="jitsuHost"
          />

          <analytics-clipboard-input
            class="gl-w-full"
            :label="$options.i18n.sdkAppId"
            :description="$options.i18n.sdkAppIdDescription"
            :value="jitsuProjectId"
          />
        </gl-dropdown-form>
      </gl-dropdown>
    </header>
    <ul class="content-list gl-border-t gl-border-gray-50">
      <li
        v-for="dashboard in dashboards"
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
