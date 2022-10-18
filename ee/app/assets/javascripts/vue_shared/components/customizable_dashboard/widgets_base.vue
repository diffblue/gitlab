<script>
export default {
  name: 'AnalyticsDashboardWidget',
  components: {
    CubeLineChart: () =>
      import('ee/product_analytics/dashboards/components/widgets/cube_line_chart.vue'),
  },
  props: {
    component: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    chartOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    customizations: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <div
    class="grid-stack-item-content gl-shadow gl-rounded-base gl-p-4 gl-display-flex gl-flex-direction-column"
  >
    <strong v-if="title" class="gl-mb-4" data-testid="widget-title">{{ title }}</strong>
    <component
      :is="component"
      :data="data"
      :customizations="customizations"
      :chart-options="chartOptions"
      class="gl-overflow-y-auto"
    />
  </div>
</template>
