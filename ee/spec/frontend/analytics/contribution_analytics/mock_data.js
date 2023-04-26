import contributionAnalyticsFixture from 'test_fixtures/graphql/analytics/contribution_analytics/graphql/contributions.query.graphql.json';

export { contributionAnalyticsFixture };

export const MOCK_ANALYTICS = {
  labels: ['Administrator'],

  issuesClosed: { data: [12] },
  totalIssuesCreatedCount: 6,
  totalIssuesClosedCount: 12,

  mergeRequestsCreated: { data: [24] },
  totalMergeRequestsCreatedCount: 24,
  totalMergeRequestsClosedCount: 50,
  totalMergeRequestsMergedCount: 20,

  push: { data: [34] },
  totalCommitCount: 18,
  totalPushAuthorCount: 20,
  totalPushCount: 34,
};

export const CONTRIBUTIONS_PATH = '/foo/contribution_analytics.json';

export const MOCK_MEMBERS = [
  {
    username: 'root',
    fullname: 'Administrator',
    user_web_url: '/root',
    push: 0,
    issues_created: 9,
    issues_closed: 4,
    merge_requests_created: 2,
    merge_requests_merged: 0,
    merge_requests_closed: 0,
    total_events: 51,
  },
  {
    username: 'monserrate.gleichner',
    fullname: 'Terrell Graham',
    user_web_url: '/monserrate.gleichner',
    push: 0,
    issues_created: 7,
    issues_closed: 1,
    merge_requests_created: 5,
    merge_requests_merged: 0,
    merge_requests_closed: 0,
    total_events: 49,
  },
  {
    username: 'melynda',
    fullname: 'Bryce Turcotte',
    user_web_url: '/melynda',
    push: 0,
    issues_created: 6,
    issues_closed: 1,
    merge_requests_created: 1,
    merge_requests_merged: 0,
    merge_requests_closed: 1,
    total_events: 45,
  },
];

export const MOCK_SORT_ORDERS = {
  fullname: 1,
  issuesClosed: 1,
  issuesCreated: 1,
  mergeRequestsClosed: 1,
  mergeRequestsCreated: 1,
  mergeRequestsApproved: 1,
  mergeRequestsMerged: 1,
  push: 1,
  totalEvents: 1,
};

export const MOCK_CONTRIBUTIONS = contributionAnalyticsFixture.data.group.contributions.nodes;

export const MOCK_PUSHES = [
  { count: 15, user: 'luffy' },
  { count: 19, user: 'zoro' },
  { count: 21, user: 'nami' },
];

export const MOCK_MERGE_REQUESTS = [
  { created: 5, closed: 7, merged: 4, user: 'luffy' },
  { created: 9, closed: 2, merged: 7, user: 'zoro' },
  { created: 17, closed: 27, merged: 21, user: 'nami' },
];

export const MOCK_ISSUES = [
  { created: 5, closed: 7, user: 'luffy' },
  { created: 9, closed: 2, user: 'zoro' },
  { created: 17, closed: 27, user: 'nami' },
];
