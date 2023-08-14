<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import { X_AXIS_MONTH_LABEL, X_AXIS_CATEGORY, Y_AXIS_SHARED_RUNNER_LABEL } from '../constants';

export default {
  components: {
    GlAreaChart,
  },
  i18n: {
    seriesName: s__('CICDAnalytics|Shared runner pipeline minute duration by month'),
    noSharedRunnerMinutesUsage: s__('CICDAnalytics|No shared runner minute usage data available'),
  },
  props: {
    selectedYear: {
      type: Number,
      required: true,
    },
    usageDataByYear: {
      type: Object,
      required: true,
    },
  },
  chartOptions: {
    xAxis: {
      name: X_AXIS_MONTH_LABEL,
      type: X_AXIS_CATEGORY,
    },
    yAxis: {
      name: Y_AXIS_SHARED_RUNNER_LABEL,
      axisLabel: {
        formatter: (val) => val,
      },
    },
  },
  computed: {
    chartOptions() {
      return {
        xAxis: {
          name: X_AXIS_MONTH_LABEL,
          type: X_AXIS_CATEGORY,
        },
        yAxis: {
          name: Y_AXIS_SHARED_RUNNER_LABEL,
          axisLabel: {
            formatter: (val) => val,
          },
        },
      };
    },
    chartData() {
      return [
        {
          data: this.getUsageDataSelectedYear,
          name: this.$options.i18n.seriesName,
        },
      ];
    },
    getUsageDataSelectedYear() {
      if (this.usageDataByYear && this.selectedYear) {
        return this.usageDataByYear[this.selectedYear]
          .slice()
          .sort((a, b) => {
            return new Date(a.monthIso8601) - new Date(b.monthIso8601);
          })
          .map((cur) => [
            formatDate(cur.monthIso8601, 'mmm yyyy'),
            (cur.sharedRunnersDuration / 60).toFixed(2),
          ]);
      }
      return [];
    },
  },
};
</script>
<template>
  <div class="gl-mt-4">
    <gl-area-chart :data="chartData" :option="$options.chartOptions" :width="0" responsive />
  </div>
</template>
