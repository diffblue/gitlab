<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { formatDate } from '~/lib/utils/datetime_utility';
import {
  USAGE_BY_MONTH,
  NO_CI_MINUTES_MSG,
  X_AXIS_MONTH_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_PROJECT_LABEL,
  formatWithUtc,
} from '../constants';

export default {
  components: {
    GlAreaChart,
  },
  USAGE_BY_MONTH,
  NO_CI_MINUTES_MSG,
  props: {
    selectedYear: {
      type: String,
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
      name: Y_AXIS_PROJECT_LABEL,
      axisLabel: {
        formatter: (val) => val,
      },
    },
  },
  computed: {
    chartData() {
      return [
        {
          data: this.getUsageDataSelectedYear,
          name: this.$options.USAGE_BY_MONTH,
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
          .map((cur) => [formatDate(cur.monthIso8601, 'mmm yyyy', formatWithUtc), cur.minutes]);
      }
      return [];
    },
  },
};
</script>
<template>
  <div>
    <gl-area-chart
      class="gl-mb-3"
      :data="chartData"
      :option="$options.chartOptions"
      responsive
      :width="0"
    />
  </div>
</template>
