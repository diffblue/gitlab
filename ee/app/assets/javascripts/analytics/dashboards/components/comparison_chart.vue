<script>
import { joinPaths } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { toYmd } from '~/analytics/shared/utils';
import GroupVulnerabilitiesQuery from '../graphql/group_vulnerabilities.query.graphql';
import ProjectVulnerabilitiesQuery from '../graphql/project_vulnerabilities.query.graphql';
import GroupMergeRequestsQuery from '../graphql/group_merge_requests.query.graphql';
import ProjectMergeRequestsQuery from '../graphql/project_merge_requests.query.graphql';
import GroupFlowMetricsQuery from '../graphql/group_flow_metrics.query.graphql';
import ProjectFlowMetricsQuery from '../graphql/project_flow_metrics.query.graphql';
import GroupDoraMetricsQuery from '../graphql/group_dora_metrics.query.graphql';
import ProjectDoraMetricsQuery from '../graphql/project_dora_metrics.query.graphql';
import { BUCKETING_INTERVAL_ALL, MERGE_REQUESTS_STATE_MERGED } from '../graphql/constants';
import { DASHBOARD_LOADING_FAILURE, CHART_LOADING_FAILURE } from '../constants';
import {
  fetchMetricsForTimePeriods,
  extractGraphqlVulnerabilitiesData,
  extractGraphqlDoraData,
  extractGraphqlFlowData,
  extractGraphqlMergeRequestsData,
} from '../api';
import {
  generateSkeletonTableData,
  generateMetricComparisons,
  generateSparklineCharts,
  mergeTableData,
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
    ComparisonTable,
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
      tableData: {},
      chartData: {},
    };
  },
  computed: {
    skeletonData() {
      return generateSkeletonTableData(this.excludeMetrics);
    },
    combinedData() {
      let data = this.skeletonData;
      data = mergeTableData(data, this.tableData);
      data = mergeTableData(data, this.chartData);
      return data;
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
  },
  async mounted() {
    await this.fetchTableMetrics();
    await this.fetchSparklineMetrics();
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
          this.fetchGraphqlData,
        );

        this.tableData = generateMetricComparisons(timePeriods);
      } catch (error) {
        createAlert({ message: DASHBOARD_LOADING_FAILURE, error, captureError: true });
      }
    },
    async fetchSparklineMetrics() {
      try {
        const chartData = await fetchMetricsForTimePeriods(
          CHART_TIME_PERIODS,
          this.fetchGraphqlData,
        );

        this.chartData = generateSparklineCharts(chartData);
      } catch (error) {
        createAlert({ message: CHART_LOADING_FAILURE, error, captureError: true });
      }
    },
  },
  now,
};
</script>
<template>
  <comparison-table
    :table-data="combinedData"
    :request-path="namespaceRequestPath"
    :is-project="isProject"
    :now="$options.now"
  />
</template>
