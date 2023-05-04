<script>
import { GlLoadingIcon } from '@gitlab/ui';
import dataSources from 'ee/analytics/analytics_dashboards/data_sources';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { isEmptyPanelData } from 'ee/vue_shared/components/customizable_dashboard/utils';
import { I18N_PANEL_EMPTY_STATE_MESSAGE } from './constants';

export default {
  name: 'AnalyticsDashboardPanel',
  components: {
    GlLoadingIcon,
    TooltipOnTruncate,
    LineChart: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/line_chart.vue'),
    ColumnChart: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/column_chart.vue'),
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
  computed: {
    showEmptyState() {
      return !this.error && isEmptyPanelData(this.visualization.type, this.data);
    },
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
          visualizationOptions: this.visualization.options,
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
  I18N_PANEL_EMPTY_STATE_MESSAGE,
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
    <div
      class="gl-overflow-y-auto gl-h-full"
      :class="{ 'gl--flex-center': loading || showEmptyState }"
    >
      <gl-loading-icon v-if="loading" size="lg" />

      <div v-else-if="showEmptyState" class="gl-text-center gl-text-secondary">
        {{ $options.I18N_PANEL_EMPTY_STATE_MESSAGE }}
      </div>

      <component
        :is="visualization.type"
        v-else-if="!error"
        :data="data"
        :options="visualization.options"
      />
    </div>
  </div>
</template>
