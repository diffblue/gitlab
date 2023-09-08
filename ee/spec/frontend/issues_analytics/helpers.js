export const mockGraphqlIssuesAnalyticsCountsResponse = ({ mockDataResponse } = {}) =>
  jest.fn().mockResolvedValue({
    data: {
      issuesAnalyticsCountsData: mockDataResponse,
    },
  });
