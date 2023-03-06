<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';

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
};
</script>

<template>
  <gl-line-chart :data="data" :option="options" responsive class="gl-overflow-hidden" />
</template>
