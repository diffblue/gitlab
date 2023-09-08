import { print } from 'graphql/language/printer';
import issuesAnalyticsCountsQueryBuilder from 'ee/issues_analytics/graphql/issues_analytics_counts_query_builder';
import {
  mockGroupIssuesAnalyticsCountsQuery,
  mockIssuesAnalyticsCountsStartDate,
  mockIssuesAnalyticsCountsEndDate,
  mockProjectIssuesAnalyticsCountsQuery,
} from '../mock_data';

describe('issuesAnalyticsCountsQueryBuilder', () => {
  const startDate = mockIssuesAnalyticsCountsStartDate;
  const endDate = mockIssuesAnalyticsCountsEndDate;

  it('returns the query for a group as expected', () => {
    const query = issuesAnalyticsCountsQueryBuilder(startDate, endDate);

    expect(print(query)).toEqual(mockGroupIssuesAnalyticsCountsQuery);
  });

  it('returns the query for a project as expected', () => {
    const query = issuesAnalyticsCountsQueryBuilder(startDate, endDate, true);

    expect(print(query)).toEqual(mockProjectIssuesAnalyticsCountsQuery);
  });
});
