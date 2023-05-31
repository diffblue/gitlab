<script>
import { GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { GlSparklineChart } from '@gitlab/ui/dist/charts';
import { formatDate } from '~/lib/utils/datetime_utility';
import { CHART_GRADIENT, CHART_GRADIENT_INVERTED } from '../constants';
import { generateDashboardTableFields } from '../utils';
import MetricTableCell from './metric_table_cell.vue';
import TrendIndicator from './trend_indicator.vue';

export default {
  name: 'ComparisonTable',
  components: {
    GlSkeletonLoader,
    GlTableLite,
    GlSparklineChart,
    MetricTableCell,
    TrendIndicator,
  },
  props: {
    requestPath: {
      type: String,
      required: true,
    },
    isProject: {
      type: Boolean,
      required: true,
    },
    tableData: {
      type: Array,
      required: true,
    },
    now: {
      type: Date,
      required: true,
    },
  },
  computed: {
    dashboardTableFields() {
      return generateDashboardTableFields(this.now);
    },
  },
  methods: {
    formatDate(date) {
      return formatDate(date, 'mmm d');
    },
    chartGradient(invert) {
      return invert ? CHART_GRADIENT_INVERTED : CHART_GRADIENT;
    },
  },
};
</script>
<template>
  <gl-table-lite :fields="dashboardTableFields" :items="tableData">
    <template #head()="{ field: { label, start, end } }">
      <template v-if="!start || !end">
        {{ label }}
      </template>
      <template v-else>
        <div class="gl-mb-2">{{ label }}</div>
        <div class="gl-font-weight-normal">{{ formatDate(start) }} - {{ formatDate(end) }}</div>
      </template>
    </template>

    <template #cell()="{ value: { value, change }, item: { invertTrendColor } }">
      {{ value }}
      <trend-indicator v-if="change" :change="change" :invert-color="invertTrendColor" />
    </template>

    <template #cell(metric)="{ value: { identifier } }">
      <metric-table-cell
        :data-testid="`${identifier}_metric_cell`"
        :identifier="identifier"
        :request-path="requestPath"
        :is-project="isProject"
      />
    </template>

    <template #cell(chart)="{ value: { data, tooltipLabel }, item: { invertTrendColor } }">
      <gl-sparkline-chart
        v-if="data"
        :height="30"
        :tooltip-label="tooltipLabel"
        :show-last-y-value="false"
        :data="data"
        :smooth="0.2"
        :gradient="chartGradient(invertTrendColor)"
        data-testid="metric_chart"
      />
      <div v-else class="gl-py-4" data-testid="metric_chart_skeleton">
        <gl-skeleton-loader :lines="1" :width="100" />
      </div>
    </template>
  </gl-table-lite>
</template>
