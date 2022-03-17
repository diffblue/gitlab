<script>
import { GlAlert } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import {
  USAGE_BY_MONTH,
  X_AXIS_MONTH_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_LABEL,
  NO_CI_MINUTES_MSG,
} from '../constants';

export default {
  USAGE_BY_MONTH,
  X_AXIS_MONTH_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_LABEL,
  NO_CI_MINUTES_MSG,
  components: {
    GlAlert,
    GlAreaChart,
  },
  props: {
    minutesUsageData: {
      type: Array,
      required: true,
    },
  },
  computed: {
    chartOptions() {
      return {
        xAxis: {
          name: this.$options.X_AXIS_MONTH_LABEL,
          type: this.$options.X_AXIS_CATEGORY,
        },
        yAxis: {
          name: this.$options.Y_AXIS_LABEL,
        },
      };
    },
    chartData() {
      return [
        {
          data: this.minutesUsageData,
          name: this.$options.USAGE_BY_MONTH,
        },
      ];
    },
    isDataEmpty() {
      return this.minutesUsageData.length === 0;
    },
  },
};
</script>
<template>
  <div>
    <h5>{{ $options.USAGE_BY_MONTH }}</h5>
    <gl-area-chart
      v-if="!isDataEmpty"
      class="gl-mb-3"
      :data="chartData"
      :option="chartOptions"
      responsive
      :width="0"
    />
    <gl-alert v-else class="gl-mb-5" :dismissible="false">
      {{ $options.NO_CI_MINUTES_MSG }}
    </gl-alert>
  </div>
</template>
