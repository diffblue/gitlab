<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { GlStackedColumnChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import * as Sentry from '@sentry/browser';
import { s__, n__, sprintf, __ } from '~/locale';
import { isValidDate } from '~/lib/utils/datetime_utility';
import issuesAnalyticsCountsQueryBuilder from '../graphql/issues_analytics_counts_query_builder';
import { extractIssuesAnalyticsCounts } from '../api';
import {
  TOTAL_ISSUES_ANALYTICS_CHART_COLOR_PALETTE,
  NAMESPACE_PROJECT_TYPE,
  NO_DATA_EMPTY_STATE_TYPE,
  NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE,
} from '../constants';
import IssuesAnalyticsEmptyState from './issues_analytics_empty_state.vue';

export default {
  name: 'TotalIssuesAnalyticsChart',
  components: {
    GlLoadingIcon,
    GlStackedColumnChart,
    GlChartSeriesLabel,
    GlAlert,
    IssuesAnalyticsEmptyState,
  },
  inject: {
    fullPath: {
      default: '',
    },
    type: {
      default: '',
    },
  },
  props: {
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    filters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      hasError: false,
      tooltipTitle: null,
      tooltipContent: [],
    };
  },
  apollo: {
    totalIssuesAnalyticsChartData: {
      query() {
        return issuesAnalyticsCountsQueryBuilder(this.startDate, this.endDate, this.isProject);
      },
      variables() {
        const { monthsBack, ...filters } = this.filters;

        return {
          fullPath: this.fullPath,
          ...filters,
        };
      },
      update(data) {
        return data?.issuesAnalyticsCountsData;
      },
      skip() {
        return !this.fullPath || !this.type || !this.isValidDateRange;
      },
      result() {
        if (this.shouldShowNoDataEmptyState) {
          this.$emit('hideFilteredSearchBar');
        }
      },
      error(e) {
        Sentry.captureException(e);
        this.hasError = true;
      },
    },
  },
  computed: {
    isProject() {
      return this.type === NAMESPACE_PROJECT_TYPE;
    },
    isLoading() {
      return this.$apollo.queries.totalIssuesAnalyticsChartData?.loading;
    },
    isValidDateRange() {
      return (
        isValidDate(this.startDate) && isValidDate(this.endDate) && this.endDate >= this.startDate
      );
    },
    barsData() {
      return extractIssuesAnalyticsCounts(this.totalIssuesAnalyticsChartData);
    },
    hasChartData() {
      if (!this.totalIssuesAnalyticsChartData) return false;

      return this.barsData?.some(({ data }) => data.some((value) => value > 0));
    },
    dates() {
      const { issuesOpened, issuesClosed } = this.totalIssuesAnalyticsChartData ?? {};

      const counts = issuesOpened ?? issuesClosed;

      if (!counts) return [];

      return Object.keys(counts).filter((key) => key !== '__typename');
    },
    monthLabels() {
      return this.dates.map((date) => date.split('_')[0]);
    },
    monthYearLabels() {
      return this.dates.map((date) => date.replace('_', ' '));
    },
    dateRange() {
      const { monthYearLabels } = this;

      const [startMonthYearLabel] = monthYearLabels;

      if (monthYearLabels.length === 1) return startMonthYearLabel;

      return sprintf(__('%{startDate} – %{dueDate}'), {
        startDate: startMonthYearLabel,
        dueDate: monthYearLabels.at(-1),
      });
    },
    xAxisTitle() {
      return this.$options.i18n.xAxisTitle(this.dates.length, this.dateRange);
    },
    hasFilters() {
      return Object.values(this.filters).some((filter) => Boolean(filter));
    },
    shouldShowError() {
      return !this.isLoading && this.hasError;
    },
    shouldShowEmptyState() {
      return !this.isLoading && !this.hasChartData;
    },
    shouldShowNoDataEmptyState() {
      return this.shouldShowEmptyState && !this.hasFilters;
    },
    emptyStateType() {
      return this.shouldShowNoDataEmptyState
        ? NO_DATA_EMPTY_STATE_TYPE
        : NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE;
    },
  },
  methods: {
    formatTooltipText({ seriesData }) {
      const [firstSeries] = seriesData;
      const { dataIndex } = firstSeries;

      this.tooltipTitle = this.monthYearLabels[dataIndex];
      this.tooltipContent = seriesData.map(({ seriesName, seriesId, value, componentIndex }) => ({
        seriesName,
        seriesId,
        color: this.$options.colorPalette[componentIndex],
        value,
      }));
    },
  },
  i18n: {
    yAxisTitle: s__('IssuesAnalytics|Issues Opened vs Closed'),
    xAxisTitle: (monthsCount, chartDateRange) =>
      sprintf(
        n__(
          'IssuesAnalytics|This month (%{chartDateRange})',
          'IssuesAnalytics|Last %{monthsCount} months (%{chartDateRange})',
          monthsCount,
        ),
        { monthsCount, chartDateRange },
      ),
    errorMessage: s__('IssuesAnalytics|Failed to load chart. Please try again.'),
    chartHeader: s__('IssuesAnalytics|Overview'),
  },
  colorPalette: TOTAL_ISSUES_ANALYTICS_CHART_COLOR_PALETTE,
  chartOptions: {
    xAxis: {
      axisPointer: {
        type: 'shadow',
      },
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" />
  <gl-alert v-else-if="shouldShowError" variant="danger" :dismissible="false">
    {{ $options.i18n.errorMessage }}
  </gl-alert>
  <issues-analytics-empty-state
    v-else-if="shouldShowEmptyState"
    :empty-state-type="emptyStateType"
  />
  <div v-else>
    <h4 class="gl-mt-0 gl-mb-5">{{ $options.i18n.chartHeader }}</h4>
    <gl-stacked-column-chart
      :bars="barsData"
      :y-axis-title="$options.i18n.yAxisTitle"
      :x-axis-title="xAxisTitle"
      :group-by="monthLabels"
      :option="$options.chartOptions"
      :custom-palette="$options.colorPalette"
      x-axis-type="category"
      presentation="tiled"
      :format-tooltip-text="formatTooltipText"
    >
      <template #tooltip-title>{{ tooltipTitle }}</template>
      <template #tooltip-content>
        <div
          v-for="{ seriesId, seriesName, color, value } in tooltipContent"
          :key="seriesId"
          class="gl-display-flex gl-justify-content-space-between gl-line-height-24 gl-min-w-20"
        >
          <gl-chart-series-label class="gl-font-sm" :color="color">
            {{ seriesName }}
          </gl-chart-series-label>
          <div class="gl-font-weight-bold">{{ value }}</div>
        </div>
      </template>
    </gl-stacked-column-chart>
  </div>
</template>
