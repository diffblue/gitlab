import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import {
  DASHBOARD_LOADING_FAILURE,
  CHART_LOADING_FAILURE,
} from 'ee/analytics/dashboards/constants';
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
import { DORA_METRICS, VULNERABILITY_METRICS, FLOW_METRICS } from '~/analytics/shared/constants';
import * as utils from '~/analytics/shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  doraMetricsParamsHelper,
  flowMetricsParamsHelper,
  vulnerabilityParamsHelper,
  mergeRequestsParamsHelper,
  mockAllTimePeriodApiResponses,
  mockGraphqlFlowMetricsResponse,
  mockGraphqlDoraMetricsResponse,
  mockGraphqlVulnerabilityResponse,
  mockGraphqlMergeRequestsResponse,
  expectTimePeriodRequests,
} from '../helpers';
import {
  MOCK_TABLE_TIME_PERIODS,
  MOCK_CHART_TIME_PERIODS,
  mockMonthToDateApiResponse,
  mockComparativeTableData,
  mockLastVulnerabilityCountData,
  mockDoraMetricsResponseData,
  mockFlowMetricsResponseData,
  mockMergeRequestsResponseData,
  mockExcludeMetrics,
  mockEmptyVulnerabilityResponse,
  mockEmptyDoraResponse,
  mockEmptyFlowMetricsResponse,
  mockEmptyMergeRequestsResponse,
} from '../mock_data';

const mockTypePolicy = {
  Query: { fields: { project: { merge: false }, group: { merge: false } } },
};
const mockProps = { requestPath: 'exec-group', isProject: false };
const groupPath = 'exec-group';
const allTimePeriods = [...MOCK_TABLE_TIME_PERIODS, ...MOCK_CHART_TIME_PERIODS];
const defaultGlFeatures = {
  vsdGraphqlDoraAndFlowMetrics: true,
};

jest.mock('~/alert');
jest.mock('~/analytics/shared/utils', () => ({
  fetchMetricsData: jest.fn(),
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

  const createWrapper = async ({
    props = {},
    apolloProvider = null,
    glFeatures = defaultGlFeatures,
  } = {}) => {
    wrapper = shallowMount(ComparisonChart, {
      apolloProvider,
      propsData: {
        ...mockProps,
        ...props,
      },
      provide: {
        glFeatures,
      },
    });

    await waitForPromises();
  };

  const createWrapperWithRESTApi = (params = {}) => {
    return createWrapper({ ...params, glFeatures: { vsdGraphqlDoraAndFlowMetrics: false } });
  };

  const findComparisonTable = () => wrapper.findComponent(ComparisonTable);
  const getTableData = () => findComparisonTable().props('tableData');
  const getTableDataForMetric = (identifier) =>
    getTableData().filter(({ metric }) => metric.identifier === identifier)[0];

  const expectDataRequests = (params, requestPath = '') => {
    expect(utils.fetchMetricsData).toHaveBeenCalledWith(
      [
        expect.objectContaining({
          endpoint: 'time_summary',
          name: 'time summary',
        }),
        expect.objectContaining({
          endpoint: 'summary',
          name: 'recent activity',
        }),
      ],
      requestPath,
      params,
    );
  };

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
    createAlert.mockClear();
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
    beforeEach(async () => {
      setGraphqlQueryHandlerResponses();
      mockApolloProvider = createMockApolloProvider();

      await createWrapper({
        props: { excludeMetrics: mockExcludeMetrics },
        apolloProvider: mockApolloProvider,
      });
    });

    it('does not render DORA metrics that were in excludeMetrics', () => {
      const metricNames = getTableData().map(({ metric }) => metric.identifier);
      expect(metricNames).not.toEqual(expect.arrayContaining(mockExcludeMetrics));
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
      expect(createAlert).toHaveBeenCalledWith({
        message: DASHBOARD_LOADING_FAILURE,
        captureError: true,
        error: expect.anything(),
      });
    });

    it('renders no data message', () => {
      expect(wrapper.text()).toContain('No data available');
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
      expect(createAlert).toHaveBeenCalledWith({
        message: CHART_LOADING_FAILURE,
        captureError: true,
        error: expect.anything(),
      });
    });
  });

  describe('no table data available', () => {
    // When there is no table data available the chart data requests are skipped

    beforeEach(async () => {
      setGraphqlQueryHandlerResponses({
        doraMetricsResponse: mockEmptyDoraResponse,
        flowMetricsResponse: mockEmptyFlowMetricsResponse,
        vulnerabilityResponse: mockEmptyVulnerabilityResponse,
        mergeRequestsResponse: mockEmptyMergeRequestsResponse,
      });
      mockApolloProvider = createMockApolloProvider();

      await createWrapper({ apolloProvider: mockApolloProvider });
    });

    it('will only request dora metrics for the table', () => {
      expectDoraMetricsRequests(MOCK_TABLE_TIME_PERIODS);
    });

    it('will only request flow metrics for the table', () => {
      expectFlowMetricsRequests(MOCK_TABLE_TIME_PERIODS);
    });

    it('will only request vulnerability metrics for the table', () => {
      expectVulnerabilityRequests(MOCK_TABLE_TIME_PERIODS);
    });

    it('will only merge request metrics for the table', () => {
      expectMergeRequestsRequests(MOCK_TABLE_TIME_PERIODS);
    });

    it('renders a message when theres no table data available', () => {
      expect(wrapper.text()).toContain('No data available');
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

  describe('vsdGraphqlDoraAndFlowMetrics=false', () => {
    beforeEach(() => {
      // Vulnerability data graphql query is always sent with or without the feature flag
      vulnerabilityRequestHandler = mockGraphqlVulnerabilityResponse(
        mockLastVulnerabilityCountData,
      );

      // Without the feature flag, request flow / dora metrics from the REST api
      flowMetricsRequestHandler = jest.fn();
      doraMetricsRequestHandler = jest.fn();

      mockApolloProvider = createMockApolloProvider({
        vulnerabilityRequestHandler,
        doraMetricsRequestHandler,
        flowMetricsRequestHandler,
      });
    });

    it('will request REST api flow metrics for the table', async () => {
      utils.fetchMetricsData.mockReturnValueOnce({});
      await createWrapperWithRESTApi({ apolloProvider: mockApolloProvider });

      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(MOCK_TABLE_TIME_PERIODS.length);
      MOCK_TABLE_TIME_PERIODS.forEach((timePeriod) =>
        expectDataRequests(
          {
            created_after: timePeriod.start.toISOString(),
            created_before: timePeriod.end.toISOString(),
          },
          'groups/exec-group',
        ),
      );
    });

    it('will also request the REST api chart data metrics if there is table', async () => {
      utils.fetchMetricsData.mockReturnValue(mockMonthToDateApiResponse);
      await createWrapperWithRESTApi({ apolloProvider: mockApolloProvider });

      const timePeriods = [...MOCK_TABLE_TIME_PERIODS, ...MOCK_CHART_TIME_PERIODS];
      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(timePeriods.length);
      timePeriods.forEach((timePeriod) =>
        expectDataRequests(
          {
            created_after: timePeriod.start.toISOString(),
            created_before: timePeriod.end.toISOString(),
          },
          'groups/exec-group',
        ),
      );
    });

    it('renders a message when theres no data', async () => {
      utils.fetchMetricsData.mockReturnValueOnce({});
      await createWrapperWithRESTApi({ apolloProvider: mockApolloProvider });

      expect(wrapper.text()).toContain('No data available');
    });

    it('renders each DORA metric when there is table data', async () => {
      mockAllTimePeriodApiResponses();
      await createWrapperWithRESTApi({ apolloProvider: mockApolloProvider });

      const metricNames = getTableData().map(({ metric }) => metric);
      expect(metricNames).toEqual(
        mockComparativeTableData
          .filter(({ metric }) => metric.identifier !== FLOW_METRICS.ISSUES_COMPLETED)
          .map(({ metric }) => metric),
      );
    });

    it('does not render DORA metrics that were in excludeMetrics', async () => {
      const excludeMetrics = [
        DORA_METRICS.DEPLOYMENT_FREQUENCY,
        DORA_METRICS.LEAD_TIME_FOR_CHANGES,
      ];

      mockAllTimePeriodApiResponses();
      await createWrapperWithRESTApi({
        props: { excludeMetrics },
        apolloProvider: mockApolloProvider,
      });

      const metricNames = getTableData().map(({ metric }) => metric.identifier);
      expect(metricNames).not.toEqual(expect.arrayContaining(excludeMetrics));
    });

    it('selects the final data point in the vulnerability response for display', async () => {
      mockAllTimePeriodApiResponses();
      await createWrapperWithRESTApi({ apolloProvider: mockApolloProvider });

      const critical = getTableDataForMetric(VULNERABILITY_METRICS.CRITICAL);
      const high = getTableDataForMetric(VULNERABILITY_METRICS.HIGH);

      ['thisMonth', 'lastMonth', 'twoMonthsAgo'].forEach((timePeriodKey) => {
        expect(critical[timePeriodKey].value).toBe(mockLastVulnerabilityCountData.critical);
        expect(high[timePeriodKey].value).toBe(mockLastVulnerabilityCountData.high);
      });
    });

    it('renders a chart on each row', async () => {
      utils.fetchMetricsData.mockReturnValue(mockMonthToDateApiResponse);
      await createWrapperWithRESTApi({ apolloProvider: mockApolloProvider });

      expect(getTableData().filter(({ chart }) => !chart)).toEqual([]);
    });
  });
});
