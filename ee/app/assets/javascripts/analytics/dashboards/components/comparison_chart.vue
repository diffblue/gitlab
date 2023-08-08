<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { joinPaths } from '~/lib/utils/url_utility';
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
import {
  TABLE_METRICS,
  DASHBOARD_LOADING_FAILURE,
  CHART_LOADING_FAILURE,
  SUPPORTED_DORA_METRICS,
  SUPPORTED_FLOW_METRICS,
  SUPPORTED_MERGE_REQUEST_METRICS,
  SUPPORTED_VULNERABILITY_METRICS,
} from '../constants';
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
    GlAlert,
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
      tableData: generateSkeletonTableData(this.excludeMetrics),
      failedTableMetrics: [],
      failedChartMetrics: [],
    };
  },
  computed: {
    namespaceRequestPath() {
      return this.isProject ? this.requestPath : joinPaths('groups', this.requestPath);
    },
    filteredQueries() {
      return [
        { metrics: SUPPORTED_DORA_METRICS, queryFn: this.fetchDoraMetricsQuery },
        { metrics: SUPPORTED_FLOW_METRICS, queryFn: this.fetchFlowMetricsQuery },
        { metrics: SUPPORTED_MERGE_REQUEST_METRICS, queryFn: this.fetchMergeRequestsMetricsQuery },
        {
          metrics: SUPPORTED_VULNERABILITY_METRICS,
          queryFn: this.fetchVulnerabilitiesMetricsQuery,
        },
      ].filter(({ metrics }) => this.areAnyMetricsIncluded(metrics));
    },
    tableError() {
      return this.failedTableMetrics.join(', ');
    },
    chartError() {
      return this.failedChartMetrics.join(', ');
    },
  },
  async mounted() {
    this.failedTableMetrics = await this.resolveQueries(this.fetchTableMetrics);
    this.failedChartMetrics = await this.resolveQueries(this.fetchSparklineCharts);
  },
  methods: {
    areAnyMetricsIncluded(identifiers) {
      return !identifiers.every((identifier) => this.excludeMetrics.includes(identifier));
    },

    async resolveQueries(handler) {
      const result = await Promise.allSettled(this.filteredQueries.map((query) => handler(query)));

      // Return an array of the failed metric IDs
      return result
        .reduce((acc, { reason = [] }) => acc.concat(reason), [])
        .map((metric) => TABLE_METRICS[metric].label);
    },

    async fetchTableMetrics({ metrics, queryFn }) {
      try {
        const data = await fetchMetricsForTimePeriods(DASHBOARD_TIME_PERIODS, queryFn);
        this.tableData = mergeTableData(this.tableData, generateMetricComparisons(data));
      } catch (error) {
        Sentry.captureException(error);
        throw metrics;
      }
    },

    async fetchSparklineCharts({ metrics, queryFn }) {
      try {
        const data = await fetchMetricsForTimePeriods(CHART_TIME_PERIODS, queryFn);
        this.tableData = mergeTableData(this.tableData, generateSparklineCharts(data));
      } catch (error) {
        Sentry.captureException(error);
        throw metrics;
      }
    },

    async fetchDoraMetricsQuery({ startDate, endDate }, timePeriod) {
      const result = await this.$apollo.query({
        query: this.isProject ? ProjectDoraMetricsQuery : GroupDoraMetricsQuery,
        variables: {
          fullPath: this.requestPath,
          interval: BUCKETING_INTERVAL_ALL,
          startDate,
          endDate,
        },
      });

      const responseData = extractQueryResponseFromNamespace({
        result,
        resultKey: 'dora',
      });
      return {
        ...timePeriod,
        ...extractGraphqlDoraData(responseData?.metrics || {}),
      };
    },

    async fetchFlowMetricsQuery({ startDate, endDate }, timePeriod) {
      const result = await this.$apollo.query({
        query: this.isProject ? ProjectFlowMetricsQuery : GroupFlowMetricsQuery,
        variables: {
          fullPath: this.requestPath,
          labelNames: this.filterLabels,
          startDate,
          endDate,
        },
        context: {
          // This is an expensive request that consistently exceeds our query complexity of 300 when grouped
          isSingleRequest: true,
        },
      });

      const metrics = extractQueryResponseFromNamespace({ result, resultKey: 'flowMetrics' });
      return {
        ...timePeriod,
        ...extractGraphqlFlowData(metrics || {}),
      };
    },

    async fetchMergeRequestsMetricsQuery({ startDate, endDate }, timePeriod) {
      const result = await this.$apollo.query({
        query: this.isProject ? ProjectMergeRequestsQuery : GroupMergeRequestsQuery,
        variables: {
          fullPath: this.requestPath,
          startDate: toYmd(startDate),
          endDate: toYmd(endDate),
          state: MERGE_REQUESTS_STATE_MERGED,
          labelNames: this.filterLabels.length > 0 ? this.filterLabels : null,
        },
      });

      const metrics = extractQueryResponseFromNamespace({
        result,
        resultKey: 'mergeRequests',
      });
      return {
        ...timePeriod,
        ...extractGraphqlMergeRequestsData(metrics || {}),
      };
    },

    async fetchVulnerabilitiesMetricsQuery({ endDate }, timePeriod) {
      const result = await this.$apollo.query({
        query: this.isProject ? ProjectVulnerabilitiesQuery : GroupVulnerabilitiesQuery,
        variables: {
          fullPath: this.requestPath,

          // The vulnerabilities API request takes a date, so the timezone skews it outside the monthly range
          // The vulnerabilites count returns cumulative data for each day
          // we only want to use the value of the last day in the time period
          // so we override the startDate and set it to the same value as the end date
          startDate: toYmd(endDate),
          endDate: toYmd(endDate),
        },
      });

      const responseData = extractQueryResponseFromNamespace({
        result,
        resultKey: 'vulnerabilitiesCountByDay',
      });
      return {
        ...timePeriod,
        ...extractGraphqlVulnerabilitiesData(responseData?.nodes || []),
      };
    },
  },
  now,
  i18n: {
    DASHBOARD_LOADING_FAILURE,
    CHART_LOADING_FAILURE,
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="tableError"
      class="gl-mb-3"
      data-testid="table-error-alert"
      variant="danger"
      :title="$options.i18n.DASHBOARD_LOADING_FAILURE"
      :dismissible="false"
      >{{ tableError }}</gl-alert
    >
    <gl-alert
      v-if="chartError"
      class="gl-mb-3"
      data-testid="chart-error-alert"
      variant="danger"
      :title="$options.i18n.CHART_LOADING_FAILURE"
      :dismissible="false"
      >{{ chartError }}</gl-alert
    >
    <comparison-table
      :table-data="tableData"
      :request-path="namespaceRequestPath"
      :is-project="isProject"
      :now="$options.now"
    />
  </div>
</template>
