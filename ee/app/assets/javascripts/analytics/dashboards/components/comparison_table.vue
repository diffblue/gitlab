<script>
import { GlTableLite } from '@gitlab/ui';
import { GlSparklineChart } from '@gitlab/ui/dist/charts';
import { formatDate } from '~/lib/utils/datetime_utility';
import { DASHBOARD_TABLE_FIELDS } from '../constants';
import TrendIndicator from './trend_indicator.vue';

export default {
  name: 'ComparisonTable',
  components: {
    GlTableLite,
    GlSparklineChart,
    TrendIndicator,
  },
  props: {
    tableData: {
      type: Array,
      required: true,
    },
  },
  fields: DASHBOARD_TABLE_FIELDS,
  methods: {
    formatDate(date) {
      return formatDate(date, 'mmm d');
    },
  },
};
</script>
<template>
  <gl-table-lite :fields="$options.fields" :items="tableData">
    <template #head()="{ field: { label, start, end } }">
      <template v-if="!start || !end">
        {{ label }}
      </template>
      <template v-else>
        <div class="gl-mb-2">{{ label }}</div>
        <div class="gl-font-weight-normal">{{ formatDate(start) }} - {{ formatDate(end) }}</div>
      </template>
    </template>

    <template #cell()="{ value: { value, change, invertTrendColor } }">
      {{ value }}
      <trend-indicator v-if="change" :change="change" :invert-color="invertTrendColor" />
    </template>

    <template #cell(chart)="{ value }">
      <gl-sparkline-chart
        v-if="value.data"
        :height="30"
        :tooltip-label="value.tooltipLabel"
        :show-last-y-value="false"
        :data="value.data"
      />
    </template>
  </gl-table-lite>
</template>
