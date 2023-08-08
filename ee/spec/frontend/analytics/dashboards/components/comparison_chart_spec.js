import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  SUPPORTED_DORA_METRICS,
  SUPPORTED_FLOW_METRICS,
  SUPPORTED_MERGE_REQUEST_METRICS,
  SUPPORTED_VULNERABILITY_METRICS,
} from 'ee/analytics/dashboards/constants';
import { generateSkeletonTableData } from 'ee/analytics/dashboards/utils';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import ComparisonTable from 'ee/analytics/dashboards/components/comparison_table.vue';
import GroupVulnerabilitiesQuery from 'ee/analytics/dashboards/graphql/group_vulnerabilities.query.graphql';
import ProjectVulnerabilitiesQuery from 'ee/analytics/dashboards/graphql/project_vulnerabilities.query.graphql';
import GroupFlowMetricsQuery from 'ee/analytics/dashboards/graphql/group_flow_metrics.query.graphql';
import ProjectFlowMetricsQuery from 'ee/analytics/dashboards/graphql/project_flow_metrics.query.graphql';
import GroupDoraMetricsQuery from 'ee/analytics/dashboards/graphql/group_dora_metrics.query.graphql';
import ProjectDoraMetricsQuery from 'ee/analytics/dashboards/graphql/project_dora_metrics.query.graphql';
import GroupMergeRequestsQuery from 'ee/analytics/dashboards/graphql/group_merge_requests.query.graphql';
import ProjectMergeRequestsQuery from 'ee/analytics/dashboards/graphql/project_merge_requests.query.graphql';
import { VULNERABILITY_METRICS } from '~/analytics/shared/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  doraMetricsParamsHelper,
  flowMetricsParamsHelper,
  vulnerabilityParamsHelper,
  mergeRequestsParamsHelper,
  mockGraphqlFlowMetricsResponse,
  mockGraphqlDoraMetricsResponse,
  mockGraphqlVulnerabilityResponse,
  mockGraphqlMergeRequestsResponse,
  expectTimePeriodRequests,
} from '../helpers';
import {
  MOCK_TABLE_TIME_PERIODS,
  MOCK_CHART_TIME_PERIODS,
  mockComparativeTableData,
  mockLastVulnerabilityCountData,
  mockDoraMetricsResponseData,
  mockFlowMetricsResponseData,
  mockMergeRequestsResponseData,
} from '../mock_data';

const mockTypePolicy = {
  Query: { fields: { project: { merge: false }, group: { merge: false } } },
};
const mockProps = { requestPath: 'exec-group', isProject: false };
const groupPath = 'exec-group';
const allTimePeriods = [...MOCK_TABLE_TIME_PERIODS, ...MOCK_CHART_TIME_PERIODS];

jest.mock('@sentry/browser');
jest.mock('~/alert');
jest.mock('~/analytics/shared/utils', () => ({
  toYmd: jest.requireActual('~/analytics/shared/utils').toYmd,
}));

Vue.use(VueApollo);

describe('Comparison chart', () => {
  let wrapper;
  let mockApolloProvider;
  let vulnerabilityRequestHandler = null;
  let flowMetricsRequestHandler = null;
  let doraMetricsRequestHandler = null;
  let mergeRequestsRequestHandler = null;

  const setGraphqlQueryHandlerResponses = ({
    vulnerabilityResponse = mockLastVulnerabilityCountData,
    doraMetricsResponse = mockDoraMetricsResponseData,
    flowMetricsResponse = mockFlowMetricsResponseData,
    mergeRequestsResponse = mockMergeRequestsResponseData,
  } = {}) => {
    vulnerabilityRequestHandler = mockGraphqlVulnerabilityResponse(vulnerabilityResponse);
    flowMetricsRequestHandler = mockGraphqlFlowMetricsResponse(flowMetricsResponse);
    doraMetricsRequestHandler = mockGraphqlDoraMetricsResponse(doraMetricsResponse);
    mergeRequestsRequestHandler = mockGraphqlMergeRequestsResponse(mergeRequestsResponse);
  };

  const createMockApolloProvider = ({
    isProject = false,
    flowMetricsRequest = flowMetricsRequestHandler,
    doraMetricsRequest = doraMetricsRequestHandler,
    vulnerabilityRequest = vulnerabilityRequestHandler,
    mergeRequestsRequest = mergeRequestsRequestHandler,
  } = {}) => {
    const flowMetricsQuery = isProject ? ProjectFlowMetricsQuery : GroupFlowMetricsQuery;
    const doraMetricsQuery = isProject ? ProjectDoraMetricsQuery : GroupDoraMetricsQuery;
    const vulnerabilitiesQuery = isProject
      ? ProjectVulnerabilitiesQuery
      : GroupVulnerabilitiesQuery;
    const mergeRequestsQuery = isProject ? ProjectMergeRequestsQuery : GroupMergeRequestsQuery;

    return createMockApollo(
      [
        [flowMetricsQuery, flowMetricsRequest],
        [doraMetricsQuery, doraMetricsRequest],
        [vulnerabilitiesQuery, vulnerabilityRequest],
        [mergeRequestsQuery, mergeRequestsRequest],
      ],
      {},
      {
        typePolicies: mockTypePolicy,
      },
    );
  };

  const createWrapper = async ({ props = {}, apolloProvider = null } = {}) => {
    wrapper = shallowMountExtended(ComparisonChart, {
      apolloProvider,
      propsData: {
        ...mockProps,
        ...props,
      },
    });

    await waitForPromises();
  };

  const findComparisonTable = () => wrapper.findComponent(ComparisonTable);
  const findTableErrorAlert = () => wrapper.findComponentByTestId('table-error-alert');
  const findChartErrorAlert = () => wrapper.findComponentByTestId('chart-error-alert');

  const getTableData = () => findComparisonTable().props('tableData');
  const getTableDataForMetric = (identifier) =>
    getTableData().filter(({ metric }) => metric.identifier === identifier)[0];

  const expectDoraMetricsRequests = (timePeriods, { fullPath = groupPath } = {}) =>
    expectTimePeriodRequests({
      timePeriods,
      requestHandler: doraMetricsRequestHandler,
      paramsFn: (timePeriod) => doraMetricsParamsHelper({ ...timePeriod, fullPath }),
    });

  const expectFlowMetricsRequests = (timePeriods, { fullPath = groupPath, labelNames = [] } = {}) =>
    expectTimePeriodRequests({
      timePeriods,
      requestHandler: flowMetricsRequestHandler,
      paramsFn: (timePeriod) => flowMetricsParamsHelper({ ...timePeriod, fullPath, labelNames }),
    });

  const expectVulnerabilityRequests = (timePeriods, { fullPath = groupPath } = {}) =>
    expectTimePeriodRequests({
      timePeriods,
      requestHandler: vulnerabilityRequestHandler,
      paramsFn: (timePeriod) => vulnerabilityParamsHelper({ ...timePeriod, fullPath }),
    });

  const expectMergeRequestsRequests = (
    timePeriods,
    { fullPath = groupPath, labelNames = null } = {},
  ) =>
    expectTimePeriodRequests({
      timePeriods,
      requestHandler: mergeRequestsRequestHandler,
      paramsFn: (timePeriod) => mergeRequestsParamsHelper({ ...timePeriod, fullPath, labelNames }),
    });

  afterEach(() => {
    mockApolloProvider = null;

    vulnerabilityRequestHandler.mockClear();
    flowMetricsRequestHandler.mockClear();
    doraMetricsRequestHandler.mockClear();
    mergeRequestsRequestHandler.mockClear();
  });

  describe('loading table and chart data', () => {
    beforeEach(() => {
      setGraphqlQueryHandlerResponses();
      createWrapper();
    });

    it('will pass skeleton data to the comparison table', () => {
      expect(getTableData()).toEqual(generateSkeletonTableData());
    });
  });

  describe('with table and chart data available', () => {
    beforeEach(async () => {
      setGraphqlQueryHandlerResponses();
      mockApolloProvider = createMockApolloProvider();

      await createWrapper({ apolloProvider: mockApolloProvider });
    });

    it('will request dora metrics for the table and sparklines', () => {
      expectDoraMetricsRequests(allTimePeriods);
    });

    it('will request flow metrics for the table and sparklines', () => {
      expectFlowMetricsRequests(allTimePeriods);
    });

    it('will request vulnerability metrics for the table and sparklines', () => {
      expectVulnerabilityRequests(allTimePeriods);
    });

    it('will request merge request data for the table and sparklines', () => {
      expectMergeRequestsRequests(allTimePeriods);
    });

    it('renders each DORA metric when there is table data', () => {
      const metricNames = getTableData().map(({ metric }) => metric);
      expect(metricNames).toEqual(mockComparativeTableData.map(({ metric }) => metric));
    });

    it('selects the final data point in the vulnerability response for display', () => {
      const critical = getTableDataForMetric(VULNERABILITY_METRICS.CRITICAL);
      const high = getTableDataForMetric(VULNERABILITY_METRICS.HIGH);

      ['thisMonth', 'lastMonth', 'twoMonthsAgo'].forEach((timePeriodKey) => {
        expect(critical[timePeriodKey].value).toBe(mockLastVulnerabilityCountData.critical);
        expect(high[timePeriodKey].value).toBe(mockLastVulnerabilityCountData.high);
      });
    });

    it('renders a chart on each row', () => {
      expect(getTableData().filter(({ chart }) => !chart)).toEqual([]);
    });
  });

  describe('filterLabels set', () => {
    const filterLabels = ['test::one', 'test::two'];

    beforeEach(async () => {
      setGraphqlQueryHandlerResponses();
      mockApolloProvider = createMockApolloProvider();

      await createWrapper({
        props: { filterLabels },
        apolloProvider: mockApolloProvider,
      });
    });

    it('will filter flow metrics using filterLabels', () => {
      expectFlowMetricsRequests(allTimePeriods, { labelNames: filterLabels });
    });

    it('will filter merge request data using filterLabels', () => {
      expectMergeRequestsRequests(allTimePeriods, { labelNames: filterLabels });
    });
  });

  describe('excludeMetrics set', () => {
    beforeEach(() => {
      setGraphqlQueryHandlerResponses();
      mockApolloProvider = createMockApolloProvider();
    });

    it('does not render DORA metrics that were in excludeMetrics', async () => {
      const excludeMetrics = SUPPORTED_DORA_METRICS;
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      const metricNames = getTableData().map(({ metric }) => metric.identifier);
      expect(metricNames).not.toEqual(expect.arrayContaining(excludeMetrics));
    });

    it('does not request DORA metrics if they are all excluded', async () => {
      const excludeMetrics = SUPPORTED_DORA_METRICS;
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      expect(doraMetricsRequestHandler).not.toHaveBeenCalled();
    });

    it('requests DORA metrics if at least one is included', async () => {
      const excludeMetrics = SUPPORTED_DORA_METRICS.splice(1);
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      expect(doraMetricsRequestHandler).toHaveBeenCalled();
    });

    it('does not request flow metrics if they are all excluded', async () => {
      const excludeMetrics = SUPPORTED_FLOW_METRICS;
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      expect(flowMetricsRequestHandler).not.toHaveBeenCalled();
    });

    it('requests flow metrics if at least one is included', async () => {
      const excludeMetrics = SUPPORTED_FLOW_METRICS.splice(1);
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      expect(flowMetricsRequestHandler).toHaveBeenCalled();
    });

    it('does not request vulnerability metrics if they are all excluded', async () => {
      const excludeMetrics = SUPPORTED_VULNERABILITY_METRICS;
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      expect(vulnerabilityRequestHandler).not.toHaveBeenCalled();
    });

    it('requests vulnerability metrics if at least one is included', async () => {
      const excludeMetrics = SUPPORTED_VULNERABILITY_METRICS.splice(1);
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      expect(vulnerabilityRequestHandler).toHaveBeenCalled();
    });

    it('does not request MR metrics if throughput was excluded', async () => {
      const excludeMetrics = SUPPORTED_MERGE_REQUEST_METRICS;
      await createWrapper({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      expect(mergeRequestsRequestHandler).not.toHaveBeenCalled();
    });
  });

  describe('failed table requests', () => {
    beforeEach(async () => {
      setGraphqlQueryHandlerResponses();

      doraMetricsRequestHandler = jest.fn().mockRejectedValue({});
      mockApolloProvider = createMockApolloProvider();

      await createWrapper({ apolloProvider: mockApolloProvider });
    });

    it('will show an alert if the table data failed to load', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findTableErrorAlert().exists()).toBe(true);
      expect(findTableErrorAlert().text()).toBe('Deployment Frequency');
    });
  });

  describe('failed chart request', () => {
    const mockResolvedDoraMetricsResponse = {
      data: { namespace: { id: 'fake-dora-metrics-request', dora: mockDoraMetricsResponseData } },
    };

    beforeEach(async () => {
      setGraphqlQueryHandlerResponses();

      // The first 4 requests are for the table data, fail after that for the charts
      doraMetricsRequestHandler = jest
        .fn()
        .mockResolvedValueOnce(mockResolvedDoraMetricsResponse)
        .mockResolvedValueOnce(mockResolvedDoraMetricsResponse)
        .mockResolvedValueOnce(mockResolvedDoraMetricsResponse)
        .mockResolvedValueOnce(mockResolvedDoraMetricsResponse)
        .mockRejectedValue({});

      mockApolloProvider = createMockApolloProvider();

      await createWrapper({ apolloProvider: mockApolloProvider });
    });

    it('will show an alert if the chart data failed to load', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findChartErrorAlert().exists()).toBe(true);
      expect(findChartErrorAlert().text()).toBe('Deployment Frequency');
    });
  });

  describe('isProject=true', () => {
    const fakeProjectPath = 'fake/project/path';

    beforeEach(async () => {
      setGraphqlQueryHandlerResponses();
      mockApolloProvider = createMockApolloProvider({ isProject: true });

      await createWrapper({
        props: { isProject: true, requestPath: fakeProjectPath },
        apolloProvider: mockApolloProvider,
      });
    });

    it('will request project dora metrics for the table and sparklines', () => {
      expectDoraMetricsRequests(allTimePeriods, { fullPath: fakeProjectPath });
    });

    it('will request project flow metrics for the table and sparklines', () => {
      expectFlowMetricsRequests(allTimePeriods, { fullPath: fakeProjectPath });
    });

    it('will request project vulnerability metrics for the table and sparklines', () => {
      expectVulnerabilityRequests(allTimePeriods, { fullPath: fakeProjectPath });
    });
  });
});
