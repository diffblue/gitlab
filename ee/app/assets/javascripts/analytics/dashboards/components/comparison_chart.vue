<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { fetchMetricsData } from '~/analytics/shared/utils';
import { METRICS_REQUESTS } from '~/analytics/cycle_analytics/constants';
import {
  DASHBOARD_DESCRIPTION_GROUP,
  DASHBOARD_DESCRIPTION_PROJECT,
  DASHBOARD_LOADING_FAILURE,
  DASHBOARD_NO_DATA,
  CHART_LOADING_FAILURE,
} from '../constants';
import {
  fetchMetricsForTimePeriods,
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
  generateSparklineCharts,
  mergeSparklineCharts,
  generateDateRanges,
  generateChartTimePeriods,
  extractDoraMetrics,
} from '../utils';
import ComparisonTable from './comparison_table.vue';

const now = new Date();
const DASHBOARD_TIME_PERIODS = generateDateRanges(now);
const CHART_TIME_PERIODS = generateChartTimePeriods(now);

export default {
  name: 'ComparisonChart',
  components: {
    GlAlert,
    GlSkeletonLoader,
    ComparisonTable,
  },
  props: {
    requestPath: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    isProject: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      tableData: [],
      chartData: {},
      loadingTable: false,
    };
  },
  computed: {
    hasData() {
      return Boolean(this.allData.length);
    },
    hasTableData() {
      return Boolean(this.tableData.length);
    },
    hasChartData() {
      return Boolean(Object.keys(this.chartData).length);
    },
    allData() {
      return this.hasChartData
        ? mergeSparklineCharts(this.tableData, this.chartData)
        : this.tableData;
    },
    description() {
      const { name } = this;
      const text = this.isProject ? DASHBOARD_DESCRIPTION_PROJECT : DASHBOARD_DESCRIPTION_GROUP;
      return sprintf(text, { name });
    },
    namespaceRequestPath() {
      return this.isProject ? this.requestPath : joinPaths('groups', this.requestPath);
    },
  },
  async mounted() {
    this.loadingTable = true;
    try {
      await this.fetchTableMetrics();
      if (this.hasTableData) {
        await this.fetchSparklineMetrics();
      }
    } finally {
      this.loadingTable = false;
    }
  },
  methods: {
    async fetchMetrics({ startDate, endDate }, timePeriod) {
      // request the dora and flow metrics from the REST endpoint
      const rawData = await fetchMetricsData(METRICS_REQUESTS, this.namespaceRequestPath, {
        created_after: startDate,
        created_before: endDate,
      });

      return { ...timePeriod, ...extractDoraMetrics(rawData) };
    },
    async fetchTableMetrics() {
      try {
        const tableData = await fetchMetricsForTimePeriods(
          DASHBOARD_TIME_PERIODS,
          this.fetchMetrics,
        );

        this.tableData = hasDoraMetricValues(tableData)
          ? generateDoraTimePeriodComparisonTable(tableData)
          : [];
      } catch (error) {
        createAlert({ message: DASHBOARD_LOADING_FAILURE, error, captureError: true });
      }
    },
    async fetchSparklineMetrics() {
      try {
        const chartData = await fetchMetricsForTimePeriods(CHART_TIME_PERIODS, this.fetchMetrics);
        this.chartData = hasDoraMetricValues(chartData) ? generateSparklineCharts(chartData) : {};
      } catch (error) {
        createAlert({ message: CHART_LOADING_FAILURE, error, captureError: true });
      }
    },
  },
  i18n: {
    noData: DASHBOARD_NO_DATA,
  },
  now,
};
</script>
<template>
  <div>
    <h5>{{ description }}</h5>
    <gl-skeleton-loader v-if="loadingTable" />
    <gl-alert v-else-if="!hasData" variant="info" :dismissible="false">{{
      $options.i18n.noData
    }}</gl-alert>
    <comparison-table
      v-else
      :table-data="allData"
      :request-path="namespaceRequestPath"
      :is-project="isProject"
      :now="$options.now"
    />
  </div>
</template>
