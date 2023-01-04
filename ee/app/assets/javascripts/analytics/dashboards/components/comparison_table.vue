<script>
import { GlTableLite } from '@gitlab/ui';
import { GlSparklineChart } from '@gitlab/ui/dist/charts';
import { s__, __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import MetricPopover from '~/analytics/shared/components/metric_popover.vue';
import { DASHBOARD_TABLE_FIELDS, METRIC_TOOLTIPS } from '../constants';
import TrendIndicator from './trend_indicator.vue';

export default {
  name: 'ComparisonTable',
  components: {
    GlTableLite,
    GlSparklineChart,
    MetricPopover,
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
  },
  fields: DASHBOARD_TABLE_FIELDS,
  methods: {
    formatDate(date) {
      return formatDate(date, 'mmm d');
    },
    popoverTarget(identifier) {
      return `${this.requestPath}__${identifier}`.replace('/', '_');
    },
    popoverMetric(identifier, label) {
      const { description, groupLink, projectLink, docsLink } = METRIC_TOOLTIPS[identifier];
      const dashboardLink = `/${this.requestPath}/${this.isProject ? projectLink : groupLink}`;
      return {
        label,
        description,
        links: [
          { url: dashboardLink, label: this.$options.i18n.popoverDashboardLabel, name: label },
          { url: docsLink, label: this.$options.i18n.popoverDocsLabel, docs_link: true },
        ],
      };
    },
  },
  i18n: {
    popoverDashboardLabel: __('Dashboard'),
    popoverDocsLabel: s__('DORA4Metrics|Go to docs'),
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

    <template #cell(metric)="{ value: { identifier, value } }">
      <span :id="popoverTarget(identifier)">{{ value }}</span>
      <metric-popover
        :target="popoverTarget(identifier)"
        :metric="popoverMetric(identifier, value)"
        :data-testid="`${identifier}_popover`"
      />
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
