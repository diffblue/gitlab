<script>
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from 'ee/ci_minutes_usage/components/minutes_usage_project_chart.vue';

export default {
  name: 'MinutesUsageCharts',
  components: { MinutesUsageMonthChart, MinutesUsageProjectChart },
  inject: ['ciMinutesDisplayMinutesAvailableData'],
  props: {
    ciMinutesUsages: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  borderStyles: 'gl-border-b-solid gl-border-gray-200 gl-border-b-1',
};
</script>

<template>
  <div :class="$options.borderStyles" class="gl-my-7">
    <minutes-usage-month-chart :class="$options.borderStyles" :ci-minutes-usage="ciMinutesUsages" />
    <minutes-usage-project-chart :minutes-usage-data="ciMinutesUsages" />
  </div>
</template>
