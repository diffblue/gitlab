<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import { createAlert } from '~/flash';
import {
  DASHBOARD_DESCRIPTION_GROUP,
  DASHBOARD_DESCRIPTION_PROJECT,
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
import ComparisonTable from './comparison_table.vue';

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
};
</script>
<template>
  <div>
    <h4>{{ description }}</h4>
    <gl-skeleton-loader v-if="loadingTable" />
    <comparison-table v-else-if="hasData" :table-data="allData" />
    <gl-alert v-else variant="info" :dismissible="false">{{ $options.i18n.noData }}</gl-alert>
  </div>
</template>
