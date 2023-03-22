<script>
import { GlColumnChart } from '@gitlab/ui/dist/charts';

export default {
  name: 'ColumnChart',
  components: {
    GlColumnChart,
  },
  props: {
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    options: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-column-chart
    :x-axis-type="options.xAxis.type"
    :x-axis-title="options.xAxis.name"
    :y-axis-title="options.yAxis.name"
    :bars="data"
    :option="options"
    height="auto"
    responsive
    data-testid="dashboard-visualization-column-chart"
    class="gl-overflow-hidden"
  />
</template>
