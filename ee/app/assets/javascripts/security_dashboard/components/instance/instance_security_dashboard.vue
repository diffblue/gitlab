<script>
import { GlLoadingIcon } from '@gitlab/ui';
import instanceProjectsQuery from 'ee/security_dashboard/graphql/queries/instance_projects.query.graphql';
import vulnerabilityGradesQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_grades.query.graphql';
import vulnerabilityHistoryQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_history.query.graphql';
import { PROJECT_LOADING_ERROR_MESSAGE } from 'ee/security_dashboard/helpers';
import createFlash from '~/flash';
import ReportNotConfigured from '../shared/empty_states/report_not_configured_instance.vue';
import VulnerabilitySeverities from '../shared/project_security_status_chart.vue';
import SecurityDashboardLayout from '../shared/security_dashboard_layout.vue';
import VulnerabilitiesOverTimeChart from '../shared/vulnerabilities_over_time_chart.vue';

export default {
  components: {
    GlLoadingIcon,
    ReportNotConfigured,
    SecurityDashboardLayout,
    VulnerabilitySeverities,
    VulnerabilitiesOverTimeChart,
  },
  apollo: {
    projects: {
      query: instanceProjectsQuery,
      update(data) {
        return data?.instance?.projects?.nodes ?? [];
      },
      error() {
        createFlash({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
    },
  },
  data() {
    return {
      projects: [],
      vulnerabilityHistoryQuery,
      vulnerabilityGradesQuery,
    };
  },
  computed: {
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading;
    },
    shouldShowCharts() {
      return Boolean(!this.isLoadingProjects && this.projects.length);
    },
    shouldShowEmptyState() {
      return !this.isLoadingProjects && !this.projects.length;
    },
  },
};
</script>

<template>
  <security-dashboard-layout>
    <template v-if="shouldShowEmptyState" #empty-state>
      <report-not-configured />
    </template>
    <template v-else-if="shouldShowCharts" #default>
      <vulnerabilities-over-time-chart :query="vulnerabilityHistoryQuery" />
      <vulnerability-severities :query="vulnerabilityGradesQuery" />
    </template>
    <template v-else #loading>
      <gl-loading-icon size="lg" class="gl-mt-6" />
    </template>
  </security-dashboard-layout>
</template>
