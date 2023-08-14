<script>
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import {
  X_AXIS_PROJECT_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_PROJECT_LABEL,
  Y_AXIS_SHARED_RUNNER_LABEL,
  NO_CI_MINUTES_MSG,
} from '../constants';

export default {
  X_AXIS_PROJECT_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_PROJECT_LABEL,
  Y_AXIS_SHARED_RUNNER_LABEL,
  NO_CI_MINUTES_MSG,
  components: {
    GlColumnChart,
  },
  props: {
    displaySharedRunnerData: {
      type: Boolean,
      required: false,
      default: false,
    },
    usageDataByYear: {
      type: Object,
      required: true,
    },
    selectedYear: {
      type: Number,
      required: true,
    },
    selectedMonth: {
      type: Number,
      required: true,
    },
  },
  chartOptions: {
    yAxis: {
      axisLabel: {
        formatter: (val) => val,
      },
    },
  },
  data() {
    return {
      formattedData: [],
    };
  },
  computed: {
    chartData() {
      return [
        {
          data: this?.selectedMonthProjectsData,
        },
      ];
    },
    selectedMonthProjectsData() {
      const selectedMonthData = this.usageDataByYear?.[this.selectedYear]?.[this.selectedMonth];
      if (!selectedMonthData) return [];

      return selectedMonthData.projects.nodes.map((cur) => {
        return this.displaySharedRunnerData
          ? [cur.project.name, (cur.sharedRunnersDuration / 60).toFixed(2)]
          : [cur.project.name, cur.minutes];
      });
    },
    yAxisTitle() {
      return this.displaySharedRunnerData
        ? this.$options.Y_AXIS_SHARED_RUNNER_LABEL
        : this.$options.Y_AXIS_PROJECT_LABEL;
    },
  },
};
</script>
<template>
  <gl-column-chart
    class="gl-mb-3"
    responsive
    :width="0"
    :bars="chartData"
    :option="$options.chartOptions"
    :y-axis-title="yAxisTitle"
    :x-axis-title="$options.X_AXIS_PROJECT_LABEL"
    :x-axis-type="$options.X_AXIS_CATEGORY"
  />
</template>
