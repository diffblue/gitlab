<script>
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';

export default {
  name: 'DoraChart',
  components: {
    ComparisonChart,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    // Part of the visualizations API, but left unused for dora chart.
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <comparison-chart
    :request-path="data.namespace.requestPath"
    :is-project="Boolean(data.namespace.isProject)"
    :exclude-metrics="data.excludeMetrics"
    :filter-labels="data.filterLabels"
  />
</template>
