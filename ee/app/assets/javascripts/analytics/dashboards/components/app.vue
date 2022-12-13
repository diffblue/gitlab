<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { createAlert } from '~/flash';
import {
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_LOADING_FAILURE,
  DASHBOARD_NO_DATA,
  DASHBOARD_TIME_PERIODS,
  CHART_TIME_PERIODS,
  CHART_LOADING_FAILURE,
} from '../constants';
import {
  fetchDoraMetrics,
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
  generateSparklineCharts,
  mergeSparklineCharts,
} from '../utils';
import DoraComparisonTable from './dora_comparison_table.vue';

export default {
  name: 'DashboardsApp',
  components: {
    GlAlert,
    GlSkeletonLoader,
    DoraComparisonTable,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    groupName: {
      type: String,
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
    hasChartData() {
      return Boolean(Object.keys(this.chartData).length);
    },
    allData() {
      return this.hasChartData
        ? mergeSparklineCharts(this.tableData, this.chartData)
        : this.tableData;
    },
    description() {
      const { groupName } = this;
      return sprintf(this.$options.i18n.description, { groupName });
    },
    requestPath() {
      return `groups/${this.groupFullPath}`;
    },
  },
  mounted() {
    this.fetchTableData();
  },
  methods: {
    fetchTableData() {
      this.loadingTable = true;

      fetchDoraMetrics({
        timePeriods: DASHBOARD_TIME_PERIODS,
        requestPath: this.requestPath,
      })
        .then((response) => {
          if (hasDoraMetricValues(response)) {
            this.tableData = generateDoraTimePeriodComparisonTable(response);
            this.fetchChartData();
          }
        })
        .catch(() => {
          createAlert({ message: DASHBOARD_LOADING_FAILURE });
        })
        .finally(() => {
          this.loadingTable = false;
        });
    },
    fetchChartData() {
      fetchDoraMetrics({
        timePeriods: CHART_TIME_PERIODS,
        requestPath: this.requestPath,
      })
        .then((response) => {
          if (hasDoraMetricValues(response)) {
            this.chartData = generateSparklineCharts(response);
          }
        })
        .catch(() => {
          createAlert({ message: CHART_LOADING_FAILURE });
        });
    },
  },
  i18n: {
    title: DASHBOARD_TITLE,
    description: DASHBOARD_DESCRIPTION,
    noData: DASHBOARD_NO_DATA,
  },
};
</script>
<template>
  <div>
    <h1 class="page-title">{{ $options.i18n.title }}</h1>
    <h4>{{ description }}</h4>
    <gl-skeleton-loader v-if="loadingTable" />
    <dora-comparison-table v-else-if="hasData" :table-data="allData" />
    <gl-alert v-else variant="info" :dismissible="false">{{ $options.i18n.noData }}</gl-alert>
  </div>
</template>
