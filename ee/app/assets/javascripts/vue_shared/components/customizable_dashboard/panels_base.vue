<script>
import { GlLoadingIcon } from '@gitlab/ui';
import dataSources from 'ee/analytics/analytics_dashboards/data_sources';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

export default {
  name: 'AnalyticsDashboardPanel',
  components: {
    GlLoadingIcon,
    TooltipOnTruncate,
    LineChart: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/line_chart.vue'),
    DataTable: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/data_table.vue'),
    SingleStat: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/single_stat.vue'),
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
    filters: {
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
    filters: 'fetchData',
  },
  methods: {
    async fetchData() {
      const { projectId, queryOverrides, filters } = this;
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
          filters,
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
    class="grid-stack-item-content gl-shadow-sm gl-rounded-base gl-p-4 gl-display-flex gl-flex-direction-column gl-bg-white"
  >
    <tooltip-on-truncate
      v-if="title"
      :title="title"
      placement="top"
      boundary="viewport"
      class="gl-pb-3 gl-text-truncate"
    >
      <strong>{{ title }}</strong>
    </tooltip-on-truncate>
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
