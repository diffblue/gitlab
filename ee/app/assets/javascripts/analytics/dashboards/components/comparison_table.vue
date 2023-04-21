<script>
import { GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { GlSparklineChart } from '@gitlab/ui/dist/charts';
import { s__, __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import MetricPopover from '~/analytics/shared/components/metric_popover.vue';
import { METRIC_TOOLTIPS } from '~/analytics/shared/constants';
import { CHART_GRADIENT, CHART_GRADIENT_INVERTED } from '../constants';
import { generateDashboardTableFields } from '../utils';
import TrendIndicator from './trend_indicator.vue';

export default {
  name: 'ComparisonTable',
  components: {
    GlSkeletonLoader,
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
    chartGradient(invert) {
      return invert ? CHART_GRADIENT_INVERTED : CHART_GRADIENT;
    },
  },
  i18n: {
    popoverDashboardLabel: __('Dashboard'),
    popoverDocsLabel: s__('DORA4Metrics|Go to docs'),
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

    <template #cell(metric)="{ value: { identifier, value } }">
      <span :id="popoverTarget(identifier)">{{ value }}</span>
      <metric-popover
        :target="popoverTarget(identifier)"
        :metric="popoverMetric(identifier, value)"
        :data-testid="`${identifier}_popover`"
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
