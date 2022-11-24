import Vue from 'vue';
import ContributionAnalyticsApp from './components/app.vue';

export default (el) => {
  const {
    analyticsData,
    totalPushCount,
    totalCommitCount,
    totalPushAuthorCount,
    totalMergeRequestsClosedCount,
    totalMergeRequestsCreatedCount,
    totalMergeRequestsMergedCount,
    totalIssuesCreatedCount,
    totalIssuesClosedCount,
    memberContributionsPath,
  } = el.dataset;

  const {
    labels,
    push,
    merge_requests_created: mergeRequestsCreated,
    issues_closed: issuesClosed,
  } = JSON.parse(analyticsData);

  return new Vue({
    el,
    provide: {
      memberContributionsPath,
      labels,

      push,
      totalPushCount: Number(totalPushCount),
      totalCommitCount: Number(totalCommitCount),
      totalPushAuthorCount: Number(totalPushAuthorCount),

      mergeRequestsCreated,
      totalMergeRequestsClosedCount: Number(totalMergeRequestsClosedCount),
      totalMergeRequestsCreatedCount: Number(totalMergeRequestsCreatedCount),
      totalMergeRequestsMergedCount: Number(totalMergeRequestsMergedCount),

      issuesClosed,
      totalIssuesCreatedCount: Number(totalIssuesCreatedCount),
      totalIssuesClosedCount: Number(totalIssuesClosedCount),
    },
    render(createElement) {
      return createElement(ContributionAnalyticsApp);
    },
  });
};
