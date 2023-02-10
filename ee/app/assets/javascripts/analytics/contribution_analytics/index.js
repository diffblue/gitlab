import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import LegacyApp from './legacy_components/app.vue';
import App from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (el) => {
  const {
    fullPath,
    startDate,
    endDate,
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
    apolloProvider,
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
      const app = gon.features.contributionAnalyticsGraphql ? App : LegacyApp;
      return createElement(app, {
        props: { fullPath, startDate, endDate },
      });
    },
  });
};
