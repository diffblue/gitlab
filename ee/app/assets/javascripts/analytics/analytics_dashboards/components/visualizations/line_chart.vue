<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';
import merge from 'lodash/merge';

export default {
  name: 'LineChart',
  components: {
    GlLineChart,
  },
  props: {
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    fullOptions() {
      return merge({ yAxis: { min: 0 } }, this.options);
    },
  },
};
</script>

<template>
  <gl-line-chart
    :data="data"
    :option="fullOptions"
    height="auto"
    responsive
    class="gl-overflow-hidden"
  />
</template>
