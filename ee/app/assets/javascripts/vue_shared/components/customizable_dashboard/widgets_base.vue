<script>
import { GlLoadingIcon } from '@gitlab/ui';
import dataSources from 'ee/product_analytics/dashboards/data_sources';

export default {
  name: 'AnalyticsDashboardWidget',
  components: {
    GlLoadingIcon,
    LineChart: () =>
      import('ee/product_analytics/dashboards/components/visualizations/line_chart.vue'),
  },
  inject: ['projectId'],
  props: {
    visualization: {
      type: Object,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    queryOverrides: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      error: null,
      data: null,
      loading: true,
    };
  },
  async created() {
    const { type, query } = this.visualization.data;
    this.loading = true;
    this.error = null;

    try {
      const { fetch } = await dataSources[type]();
      this.data = await fetch(this.projectId, query, this.queryOverrides);
    } catch (error) {
      this.error = error;
      this.$emit('error', error);
    } finally {
      this.loading = false;
    }
  },
};
</script>

<template>
  <div
    class="grid-stack-item-content gl-shadow gl-rounded-base gl-p-4 gl-display-flex gl-flex-direction-column"
  >
    <strong v-if="title" class="gl-mb-2" data-testid="widget-title">{{ title }}</strong>
    <div class="gl-overflow-y-auto gl-h-full" :class="{ 'gl--flex-center': loading }">
      <gl-loading-icon v-if="loading" size="lg" />
      <component
        :is="visualization.type"
        v-else-if="!error"
        :data="data"
        :options="visualization.options"
      />
    </div>
  </div>
</template>
