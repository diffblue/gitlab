<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import {
  DASHBOARD_DESCRIPTION_GROUP,
  DASHBOARD_DESCRIPTION_PROJECT,
  DASHBOARD_LOADING_FAILURE,
  DASHBOARD_NO_DATA,
  CHART_LOADING_FAILURE,
} from '../constants';
import {
  fetchDoraMetrics,
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
  generateSparklineCharts,
  mergeSparklineCharts,
  generateDateRanges,
  generateChartTimePeriods,
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
  mounted() {
    this.fetchTableData();
  },
  methods: {
    fetchTableData() {
      this.loadingTable = true;

      fetchDoraMetrics({
        timePeriods: DASHBOARD_TIME_PERIODS,
        requestPath: this.namespaceRequestPath,
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
        requestPath: this.namespaceRequestPath,
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
