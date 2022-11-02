<script>
import { GlLoadingIcon } from '@gitlab/ui';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';

// TODO: Replace the hardcoded values with API calls in https://gitlab.com/gitlab-org/gitlab/-/issues/382551
const VISUALIZATION_JSONS = {
  cube_analytics_line_chart: () =>
    import(`../gl_dashboards/visualizations/cube_analytics_line_chart.json`),
};

const DASHBOARD_JSONS = {
  dashboard_overview: () => import(`../gl_dashboards/dashboard_overview.json`),
  dashboard_audience: () => import(`../gl_dashboards/dashboard_audience.json`),
};

export default {
  name: 'AnalyticsDashboard',
  components: {
    GlLoadingIcon,
    CustomizableDashboard,
  },
  data() {
    return {
      dashboard: null,
    };
  },
  async created() {
    if (DASHBOARD_JSONS[this.$route?.params.id]) {
      const dashboard = await DASHBOARD_JSONS[this.$route.params.id]();
      this.dashboard = await this.importDashboardDependencies(dashboard);
    }
  },
  methods: {
    // TODO: Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/382551
    async importVisualization(visualization) {
      const module = await VISUALIZATION_JSONS[visualization]();
      // Convert module to an object because widget_base.vue expects an object property.
      return { ...module };
    },
    async importDashboardDependencies(dashboard) {
      return {
        ...dashboard,
        widgets: await Promise.all(
          dashboard.widgets.map(async (widget) => ({
            ...widget,
            visualization: await this.importVisualization(widget.visualization),
          })),
        ),
      };
    },
  },
};
</script>

<template>
  <div>
    <template v-if="dashboard">
      <section>
        <div
          class="gl-display-flex gl-align-items-center gl-py-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
        >
          <h3 class="gl-my-0 flex-fill">{{ dashboard.title }}</h3>
          <div class="gl-display-flex">
            <router-link to="/" class="gl-button btn btn-default btn-md">
              {{ __('Go back') }}
            </router-link>
          </div>
        </div>
      </section>
      <customizable-dashboard :widgets="dashboard.widgets" />
    </template>
    <gl-loading-icon v-else size="lg" class="gl-my-7" />
  </div>
</template>
