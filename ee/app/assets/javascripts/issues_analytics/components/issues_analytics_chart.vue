<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { GlColumnChart, GlChartLegend } from '@gitlab/ui/dist/charts';
import { engineeringNotation, sum, average } from '@gitlab/ui/src/utils/number_utils';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions, mapState } from 'vuex';
import { getMonthNames } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';
import { NO_DATA_EMPTY_STATE_TYPE, NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE } from '../constants';
import IssuesAnalyticsEmptyState from './issues_analytics_empty_state.vue';

export default {
  name: 'IssuesAnalyticsChart',
  components: {
    GlLoadingIcon,
    GlColumnChart,
    GlChartLegend,
    IssuesAnalyticsEmptyState,
  },
  inject: {
    endpoint: {
      type: String,
      default: '',
    },
    noDataEmptyStateSvgPath: {
      type: String,
      default: '',
    },
    filtersEmptyStateSvgPath: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      chart: null,
    };
  },
  computed: {
    ...mapState('issueAnalytics', ['chartData', 'loading']),
    ...mapGetters('issueAnalytics', ['hasFilters', 'appliedFilters']),
    chartHasData() {
      if (!this.chartData) {
        return false;
      }

      return Object.values(this.chartData).some((val) => val > 0);
    },
    seriesData() {
      const { chartData, chartHasData } = this;

      const data = Object.keys(chartData).map((key) => {
        const date = new Date(key);
        const label = `${getMonthNames(true)[date.getUTCMonth()]} ${date.getUTCFullYear()}`;
        const val = chartData[key];

        return [label, val];
      });

      return chartHasData ? data : [];
    },
    barsData() {
      return [{ name: this.$options.i18n.seriesName, data: this.seriesData }];
    },
    chartLabels() {
      return this.seriesData.map((val) => val[0]);
    },
    chartDateRange() {
      return `${this.chartLabels[0]} - ${this.chartLabels[this.chartLabels.length - 1]}`;
    },
    showChart() {
      return !this.loading && this.chartHasData;
    },
    showEmptyState() {
      return !this.loading && !this.showChart;
    },
    showNoDataEmptyState() {
      return this.showEmptyState && !this.hasFilters;
    },
    showNoDataWithFiltersEmptyState() {
      return this.showEmptyState && this.hasFilters;
    },
    emptyStateType() {
      return this.showNoDataEmptyState
        ? NO_DATA_EMPTY_STATE_TYPE
        : NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE;
    },
    seriesDataValues() {
      return this.seriesData.map((val) => val[1]);
    },
    seriesAverage() {
      return engineeringNotation(average(...this.seriesDataValues), 0);
    },
    seriesTotal() {
      return engineeringNotation(sum(...this.seriesDataValues));
    },
    legendSeriesInfo() {
      return [
        {
          type: 'bar',
          name: this.$options.i18n.seriesName,
          color: '#1F78D1',
        },
      ];
    },
    xAxisTitle() {
      return sprintf(this.$options.i18n.xAxisTitle, {
        chartDateRange: this.chartDateRange,
      });
    },
  },
  watch: {
    appliedFilters() {
      this.fetchChartData(this.endpoint);
    },
  },
  async created() {
    await this.fetchChartData(this.endpoint);

    if (this.showNoDataEmptyState) {
      this.$emit('hasNoData');
    }
  },
  methods: {
    ...mapActions('issueAnalytics', ['fetchChartData']),
    onChartCreated(chart) {
      this.chart = chart;
    },
  },
  i18n: {
    chartHeader: s__('IssuesAnalytics|Issues created per month'),
    xAxisTitle: s__('IssuesAnalytics|Last 12 months (%{chartDateRange})'),
    seriesTotal: s__('IssuesAnalytics|Total:'),
    seriesAvg: s__('IssuesAnalytics|Avg/Month:'),
    seriesName: s__('IssuesAnalytics|Issues created'),
  },
  chartOptions: {
    dataZoom: [
      {
        type: 'slider',
        startValue: 0,
      },
    ],
  },
};
</script>
<template>
  <div class="issues-analytics-chart-wrapper">
    <gl-loading-icon v-if="loading" size="lg" class="mt-8" />
    <issues-analytics-empty-state
      v-else-if="showNoDataEmptyState || showNoDataWithFiltersEmptyState"
      :empty-state-type="emptyStateType"
    />
    <div v-else-if="showChart" data-testid="issues-analytics-chart-container">
      <h4 class="gl-mt-0 gl-mb-7">{{ $options.i18n.chartHeader }}</h4>

      <gl-column-chart
        :bars="barsData"
        :option="$options.chartOptions"
        :y-axis-title="$options.i18n.seriesName"
        :x-axis-title="xAxisTitle"
        x-axis-type="category"
        @created="onChartCreated"
      />
      <div v-if="chart" class="gl-display-flex gl-align-items-center">
        <gl-chart-legend :chart="chart" :series-info="legendSeriesInfo" />
        <div class="gl-font-sm gl-text-gray-500">
          {{ $options.i18n.seriesTotal }} {{ seriesTotal }}
          &#8226;
          {{ $options.i18n.seriesAvg }} {{ seriesAverage }}
        </div>
      </div>
    </div>
  </div>
</template>
