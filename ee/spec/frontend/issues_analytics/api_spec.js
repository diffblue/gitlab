import { extractIssuesAnalyticsCounts } from 'ee/issues_analytics/api';
import {
  mockIssuesAnalyticsCountsChartData,
  mockGroupIssuesAnalyticsCountsResponseData,
  mockProjectIssuesAnalyticsCountsResponseData,
} from './mock_data';

describe('Issues Analytics API', () => {
  describe('extractIssuesAnalyticsCounts', () => {
    describe.each`
      type         | response
      ${'group'}   | ${mockGroupIssuesAnalyticsCountsResponseData}
      ${'project'} | ${mockProjectIssuesAnalyticsCountsResponseData}
    `('$type Issues Analytics counts', ({ response }) => {
      it('prepares data for display in the chart', () => {
        expect(extractIssuesAnalyticsCounts(response)).toEqual(mockIssuesAnalyticsCountsChartData);
      });
    });
  });
});
