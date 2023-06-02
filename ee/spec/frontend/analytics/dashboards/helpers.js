import {
  BUCKETING_INTERVAL_ALL,
  MERGE_REQUESTS_STATE_MERGED,
} from 'ee/analytics/dashboards/graphql/constants';
import * as utils from '~/analytics/shared/utils';
import {
  mockDoraMetricsResponseData,
  mockFlowMetricsResponseData,
  mockLastVulnerabilityCountData,
  mockMergeRequestsResponseData,
  mockMonthToDateApiResponse,
  mockPreviousMonthApiResponse,
  mockTwoMonthsAgoApiResponse,
  mockThreeMonthsAgoApiResponse,
} from './mock_data';

export const doraMetricsParamsHelper = ({
  interval = BUCKETING_INTERVAL_ALL,
  start,
  end,
  fullPath = '',
}) => ({
  interval,
  fullPath,
  startDate: start.toISOString(),
  endDate: end.toISOString(),
});

export const flowMetricsParamsHelper = ({ start, end, fullPath = '' }) => ({
  fullPath,
  startDate: start.toISOString(),
  endDate: end.toISOString(),
});

// For the vulnerabilities request we just query for the last date in the time period
export const vulnerabilityParamsHelper = ({ fullPath, end }) => ({
  fullPath,
  startDate: utils.toYmd(end),
  endDate: utils.toYmd(end),
});

export const mergeRequestsParamsHelper = ({ start, end, fullPath = '' }) => ({
  fullPath,
  startDate: utils.toYmd(start),
  endDate: utils.toYmd(end),
  state: MERGE_REQUESTS_STATE_MERGED,
});

export const mockAllTimePeriodApiResponses = () =>
  utils.fetchMetricsData
    .mockReturnValueOnce(mockMonthToDateApiResponse)
    .mockReturnValueOnce(mockPreviousMonthApiResponse)
    .mockReturnValueOnce(mockTwoMonthsAgoApiResponse)
    .mockReturnValueOnce(mockThreeMonthsAgoApiResponse);

export const mockGraphqlVulnerabilityResponse = (
  mockDataResponse = mockLastVulnerabilityCountData,
) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: 'fake-vulnerability-request',
        vulnerabilitiesCountByDay: { nodes: [mockDataResponse] },
      },
    },
  });

export const mockGraphqlFlowMetricsResponse = (mockDataResponse = mockFlowMetricsResponseData) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: { id: 'fake-flow-metrics-request', flowMetrics: mockDataResponse },
    },
  });

export const mockGraphqlDoraMetricsResponse = (mockDataResponse = mockDoraMetricsResponseData) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: { id: 'fake-dora-metrics-request', dora: mockDataResponse },
    },
  });

export const mockGraphqlMergeRequestsResponse = (
  mockDataResponse = mockMergeRequestsResponseData,
) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: { id: 'fake-merge-requests-request', mergeRequests: mockDataResponse },
    },
  });

export const expectTimePeriodRequests = ({ requestHandler, timePeriods, paramsFn }) => {
  let params = {};
  expect(requestHandler).toHaveBeenCalledTimes(timePeriods.length);

  timePeriods.forEach((timePeriod) => {
    params = paramsFn(timePeriod);
    expect(requestHandler).toHaveBeenCalledWith(params);
  });
};
