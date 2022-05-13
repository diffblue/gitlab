<script>
import vulnerabilityGradesQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_grades.query.graphql';
import vulnerabilityHistoryQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_history.query.graphql';
import VulnerabilitySeverities from '../shared/project_security_status_chart.vue';
import SecurityDashboardLayout from '../shared/security_dashboard_layout.vue';
import VulnerabilitiesOverTimeChart from '../shared/vulnerabilities_over_time_chart.vue';
import ReportNotConfigured from './report_not_configured_instance.vue';

export default {
  components: {
    ReportNotConfigured,
    SecurityDashboardLayout,
    VulnerabilitySeverities,
    VulnerabilitiesOverTimeChart,
  },
  inject: ['hasProjects'],
  vulnerabilityHistoryQuery,
  vulnerabilityGradesQuery,
};
</script>

<template>
  <security-dashboard-layout>
    <template v-if="!hasProjects" #empty-state>
      <report-not-configured />
    </template>
    <template v-else #default>
      <vulnerabilities-over-time-chart :query="$options.vulnerabilityHistoryQuery" />
      <vulnerability-severities :query="$options.vulnerabilityGradesQuery" />
    </template>
  </security-dashboard-layout>
</template>
