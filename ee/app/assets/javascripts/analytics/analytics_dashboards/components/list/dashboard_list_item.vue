<script>
import { GlAvatar, GlIcon, GlLabel } from '@gitlab/ui';

export default {
  name: 'DashboardsListItem',
  components: {
    GlAvatar,
    GlIcon,
    GlLabel,
  },
  props: {
    dashboard: {
      type: Object,
      required: true,
    },
  },
  methods: {
    routeToDashboard() {
      return this.$router.push(this.dashboard.id);
    },
  },
};
</script>

<template>
  <li
    class="gl-display-flex! gl-px-5! gl-align-items-center gl-hover-cursor-pointer gl-hover-bg-blue-50"
    data-testid="dashboard-list-item"
    @click="routeToDashboard"
  >
    <div class="gl-float-left gl-mr-4 gl-display-flex gl-align-items-center">
      <gl-icon name="project" class="gl-text-gray-200 gl-mr-3" :size="16" />
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
          background-color="#D9C2EE"
        />
      </div>
    </div>
  </li>
</template>
