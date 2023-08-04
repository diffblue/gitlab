<script>
import { GlAvatar, GlIcon, GlLabel, GlLink } from '@gitlab/ui';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { I18N_BUILT_IN_DASHBOARD_LABEL } from '../../constants';

export default {
  name: 'DashboardsListItem',
  components: {
    GlAvatar,
    GlIcon,
    GlLabel,
    GlLink,
  },
  props: {
    dashboard: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isBuiltInDashboard() {
      return 'userDefined' in this.dashboard && !this.dashboard.userDefined;
    },
    redirectHref() {
      return joinPaths(window.location.pathname, this.dashboard.slug);
    },
  },
  methods: {
    routeToDashboard() {
      if (this.dashboard.redirect) {
        visitUrl(this.redirectHref);
      } else {
        this.$router.push(this.dashboard.slug);
      }
    },
  },
  i18n: {
    builtInLabel: I18N_BUILT_IN_DASHBOARD_LABEL,
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
        <gl-link
          v-if="dashboard.redirect"
          data-testid="dashboard-redirect-link"
          :href="redirectHref"
          class="gl-font-weight-bold gl-line-height-normal gl-text-decoration-none!"
          >{{ dashboard.title }}</gl-link
        >
        <router-link
          v-else
          data-testid="dashboard-router-link"
          class="gl-font-weight-bold gl-line-height-normal"
          :to="dashboard.slug"
          >{{ dashboard.title }}</router-link
        >
        <p
          data-testid="dashboard-description"
          class="gl-line-height-normal gl-m-0 gl-text-gray-500"
        >
          {{ dashboard.description }}
        </p>
      </div>
      <div v-if="isBuiltInDashboard" class="gl-float-right">
        <gl-label :title="$options.i18n.builtInLabel" background-color="#D9C2EE" />
      </div>
    </div>
  </li>
</template>
