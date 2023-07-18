<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { fetchMetricsData, toYmd } from '~/analytics/shared/utils';
import { FLOW_METRICS } from '~/analytics/shared/constants';
import { METRICS_REQUESTS } from '~/analytics/cycle_analytics/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GroupVulnerabilitiesQuery from '../graphql/group_vulnerabilities.query.graphql';
import ProjectVulnerabilitiesQuery from '../graphql/project_vulnerabilities.query.graphql';
import GroupMergeRequestsQuery from '../graphql/group_merge_requests.query.graphql';
import ProjectMergeRequestsQuery from '../graphql/project_merge_requests.query.graphql';
import GroupFlowMetricsQuery from '../graphql/group_flow_metrics.query.graphql';
import ProjectFlowMetricsQuery from '../graphql/project_flow_metrics.query.graphql';
import GroupDoraMetricsQuery from '../graphql/group_dora_metrics.query.graphql';
import ProjectDoraMetricsQuery from '../graphql/project_dora_metrics.query.graphql';
import { BUCKETING_INTERVAL_ALL, MERGE_REQUESTS_STATE_MERGED } from '../graphql/constants';
import { DASHBOARD_LOADING_FAILURE, DASHBOARD_NO_DATA, CHART_LOADING_FAILURE } from '../constants';
import {
  fetchMetricsForTimePeriods,
  extractGraphqlVulnerabilitiesData,
  extractGraphqlDoraData,
  extractDoraMetrics,
  extractGraphqlFlowData,
  extractGraphqlMergeRequestsData,
} from '../api';
import {
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
  generateSparklineCharts,
  mergeSparklineCharts,
  generateDateRanges,
  generateChartTimePeriods,
  generateValueStreamDashboardStartDate,
} from '../utils';
import ComparisonTable from './comparison_table.vue';

const now = generateValueStreamDashboardStartDate();
const DASHBOARD_TIME_PERIODS = generateDateRanges(now);
const CHART_TIME_PERIODS = generateChartTimePeriods(now);

const extractQueryResponseFromNamespace = ({ result, resultKey }) => {
  if (result.data?.namespace) {
    const { namespace } = result.data;
    return namespace[resultKey];
  }
  return {};
};

export default {
  name: 'ComparisonChart',
  components: {
    GlAlert,
    GlSkeletonLoader,
    ComparisonTable,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    requestPath: {
      type: String,
      required: true,
    },
    isProject: {
      type: Boolean,
      required: true,
    },
    excludeMetrics: {
      type: Array,
      required: false,
      default: () => [],
    },
    filterLabels: {
      type: Array,
      required: false,
      default: () => [],
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
    useGraphqlEndpoint() {
      return this.glFeatures.vsdGraphqlDoraAndFlowMetrics;
    },
    apiQueryFn() {
      return this.useGraphqlEndpoint ? this.fetchGraphqlData : this.fetchDoraAndFlowMetrics;
    },
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
    namespaceRequestPath() {
      return this.isProject ? this.requestPath : joinPaths('groups', this.requestPath);
    },
    defaultQueryParams() {
      return {
        isProject: this.isProject,
        fullPath: this.requestPath,
      };
    },
    excludedMetrics() {
      return [
        ...this.excludeMetrics,
        ...(this.useGraphqlEndpoint ? [] : [FLOW_METRICS.ISSUES_COMPLETED]),
      ];
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
    async fetchFlowMetricsQuery({ isProject, ...variables }) {
      const result = await this.$apollo.query({
        query: isProject ? ProjectFlowMetricsQuery : GroupFlowMetricsQuery,
        variables,
        context: {
          // This is an expensive request that consistently exceeds our query complexity of 300 when grouped
          isSingleRequest: true,
        },
      });

      return extractQueryResponseFromNamespace({ result, resultKey: 'flowMetrics' });
    },
    async fetchDoraMetricsQuery({
      isProject,
      interval = BUCKETING_INTERVAL_ALL,
      ...queryVariables
    }) {
      const result = await this.$apollo.query({
        query: isProject ? ProjectDoraMetricsQuery : GroupDoraMetricsQuery,
        variables: { ...queryVariables, interval },
      });

      const responseData = extractQueryResponseFromNamespace({
        result,
        resultKey: 'dora',
      });
      return responseData?.metrics || {};
    },
    async fetchMergeRequestsQuery({ isProject, ...variables }) {
      const result = await this.$apollo.query({
        query: isProject ? ProjectMergeRequestsQuery : GroupMergeRequestsQuery,
        variables,
      });

      const responseData = extractQueryResponseFromNamespace({
        result,
        resultKey: 'mergeRequests',
      });
      return responseData || {};
    },
    async fetchVulnerabilitiesQuery({ isProject, ...variables }) {
      const result = await this.$apollo.query({
        query: isProject ? ProjectVulnerabilitiesQuery : GroupVulnerabilitiesQuery,
        variables,
      });

      const responseData = extractQueryResponseFromNamespace({
        result,
        resultKey: 'vulnerabilitiesCountByDay',
      });
      return responseData?.nodes || [];
    },
    async fetchDoraAndFlowMetrics({ startDate, endDate }, timePeriod) {
      // request the dora and flow metrics from the REST endpoint
      const rawData = await fetchMetricsData(METRICS_REQUESTS, this.namespaceRequestPath, {
        created_after: startDate,
        created_before: endDate,
      });

      // The vulnerabilities API request takes a date, so the timezone skews it outside the monthly range
      // The vulnerabilites count returns cumulative data for each day
      // we only want to use the value of the last day in the time period
      // so we override the startDate and set it to the same value as the end date
      const vulnerabilities = await this.fetchVulnerabilitiesQuery({
        ...this.defaultQueryParams,
        startDate: toYmd(endDate),
        endDate: toYmd(endDate),
      });

      const mergeRequests = await this.fetchMergeRequestsQuery({
        ...this.defaultQueryParams,
        startDate: toYmd(startDate),
        endDate: toYmd(endDate),
        state: MERGE_REQUESTS_STATE_MERGED,
      });

      return {
        ...timePeriod,
        ...extractDoraMetrics(rawData),
        ...extractGraphqlVulnerabilitiesData(vulnerabilities),
        ...extractGraphqlMergeRequestsData(mergeRequests),
      };
    },

    async fetchGraphqlData({ startDate, endDate }, timePeriod) {
      const dora = await this.fetchDoraMetricsQuery({
        ...this.defaultQueryParams,
        startDate,
        endDate,
      });

      const flowMetrics = await this.fetchFlowMetricsQuery({
        ...this.defaultQueryParams,
        startDate,
        endDate,
        labelNames: this.filterLabels,
      });

      // The vulnerabilities API request takes a date, so the timezone skews it outside the monthly range
      // The vulnerabilites count returns cumulative data for each day
      // we only want to use the value of the last day in the time period
      // so we override the startDate and set it to the same value as the end date
      const vulnerabilities = await this.fetchVulnerabilitiesQuery({
        ...this.defaultQueryParams,
        startDate: toYmd(endDate),
        endDate: toYmd(endDate),
      });

      const mergeRequests = await this.fetchMergeRequestsQuery({
        ...this.defaultQueryParams,
        startDate: toYmd(startDate),
        endDate: toYmd(endDate),
        state: MERGE_REQUESTS_STATE_MERGED,
        labelNames: this.filterLabels.length > 0 ? this.filterLabels : null,
      });

      return {
        ...timePeriod,
        ...extractGraphqlFlowData(flowMetrics),
        ...extractGraphqlDoraData(dora),
        ...extractGraphqlVulnerabilitiesData(vulnerabilities),
        ...extractGraphqlMergeRequestsData(mergeRequests),
      };
    },
    async fetchTableMetrics() {
      try {
        const timePeriods = await fetchMetricsForTimePeriods(
          DASHBOARD_TIME_PERIODS,
          this.apiQueryFn,
        );

        this.tableData = hasDoraMetricValues(timePeriods)
          ? generateDoraTimePeriodComparisonTable({
              timePeriods,
              excludeMetrics: this.excludedMetrics,
            })
          : [];
      } catch (error) {
        createAlert({ message: DASHBOARD_LOADING_FAILURE, error, captureError: true });
      }
    },
    async fetchSparklineMetrics() {
      try {
        const chartData = await fetchMetricsForTimePeriods(CHART_TIME_PERIODS, this.apiQueryFn);

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
