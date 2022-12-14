<script>
import { GlAvatar, GlIcon, GlLabel, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import jsonList from '../gl_dashboards/analytics_dashboards.json';
import { I18N_DASHBOARD_LIST } from '../constants';

export default {
  name: 'AnalyticsDashboard',
  components: {
    GlAvatar,
    GlIcon,
    GlLabel,
    GlLink,
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
    <h2 data-testid="title">{{ $options.i18n.title }}</h2>
    <p data-testid="description">
      {{ $options.i18n.description }}
      <gl-link data-testid="help-link" :href="$options.helpPageUrl">{{
        $options.i18n.learnMore
      }}</gl-link>
    </p>
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
