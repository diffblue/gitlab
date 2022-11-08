<script>
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';

const DASHBOARD_JSONS = {
  dashboard_overview: () => import(`../gl_dashboards/dashboard_overview.json`),
  dashboard_audience: () => import(`../gl_dashboards/dashboard_audience.json`),
};

export default {
  name: 'AnalyticsDashboard',
  components: {
    CustomizableDashboard,
  },
  data() {
    return {
      dashboard: null,
    };
  },
  async created() {
    if (DASHBOARD_JSONS[this.$route?.params.id]) {
      this.dashboard = await DASHBOARD_JSONS[this.$route.params.id]();
    }
  },
};
</script>

<template>
  <div v-if="dashboard">
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
  </div>
</template>
