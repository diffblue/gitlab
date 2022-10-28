<script>
import { GlIcon, GlLabel } from '@gitlab/ui';
import jsonList from '../gl_dashboards/analytics_dashboards.json';

export default {
  name: 'AnalyticsDashboard',
  components: {
    GlIcon,
    GlLabel,
  },
  data() {
    return {
      dashboards: jsonList.internalDashboards,
    };
  },
};
</script>

<template>
  <div>
    <ul class="content-list">
      <li v-for="dashboard in dashboards" :key="dashboard.id">
        <div class="gl-float-left gl-mr-4">
          <gl-icon
            data-testid="dashboard-icon"
            :name="dashboard.icon || 'dashboard'"
            class="gl-text-gray-200"
            :size="32"
          />
        </div>
        <router-link data-testid="dashboard-link" class="title" :to="dashboard.id">{{
          dashboard.title
        }}</router-link>
        <div>
          <div data-testid="dashboard-description" class="gl-display-inline">
            {{ dashboard.description }}
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
