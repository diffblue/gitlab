<script>
import { s__ } from '~/locale';
import VulnerabilitiesOverTimeChart from './vulnerabilities_over_time_chart.vue';
import VulnerabilitySeverities from './project_security_status_chart.vue';

export default {
  components: { VulnerabilitiesOverTimeChart, VulnerabilitySeverities },
  props: {
    historyQuery: {
      type: Object,
      required: true,
    },
    gradesQuery: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    title: s__('SecurityReports|Security dashboard'),
  },
};
</script>

<template>
  <div>
    <h2 class="gl-mb-6">{{ $options.i18n.title }}</h2>

    <div class="security-charts gl-display-grid">
      <vulnerabilities-over-time-chart :query="historyQuery" />
      <vulnerability-severities :query="gradesQuery" />
    </div>
  </div>
</template>
