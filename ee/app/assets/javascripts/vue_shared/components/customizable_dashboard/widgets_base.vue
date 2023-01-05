<script>
import { GlLoadingIcon } from '@gitlab/ui';
import dataSources from 'ee/product_analytics/dashboards/data_sources';

export default {
  name: 'AnalyticsDashboardWidget',
  components: {
    GlLoadingIcon,
    LineChart: () =>
      import('ee/product_analytics/dashboards/components/visualizations/line_chart.vue'),
    DataTable: () =>
      import('ee/product_analytics/dashboards/components/visualizations/data_table.vue'),
    SingleStat: () =>
      import('ee/product_analytics/dashboards/components/visualizations/single_stat.vue'),
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
  watch: {
    visualization: {
      handler: 'fetchData',
      immediate: true,
    },
    queryOverrides: 'fetchData',
  },
  methods: {
    async fetchData() {
      const { projectId, queryOverrides } = this;
      const { type: dataType, query } = this.visualization.data;
      this.loading = true;
      this.error = null;

      try {
        const { fetch } = await dataSources[dataType]();
        this.data = await fetch({
          projectId,
          query,
          queryOverrides,
          visualizationType: this.visualization.type,
        });
      } catch (error) {
        this.error = error;
        this.$emit('error', error);
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="grid-stack-item-content gl-shadow gl-rounded-base gl-p-4 gl-display-flex gl-flex-direction-column gl-bg-white"
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
