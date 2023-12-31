// Fixtures generated by: spec/frontend/fixtures/runner.rb

// List queries
import allRunnersUpgradeStatusData from 'test_fixtures/graphql/ci/runner/list/all_runners.query.graphql.upgrade_status.json';

// Dashboard queries
import mostActiveRunnersData from 'test_fixtures/graphql/ci/runner/performance/most_active_runners.graphql.json';
import runnerFailedJobsData from 'test_fixtures/graphql/ci/runner/performance/runner_failed_jobs.graphql.json';

export const runnersWaitTimes = {
  data: {
    runners: {
      jobsStatistics: {
        queuedDuration: {
          p99: 99,
          p90: 90,
          p75: 75,
          p50: 50,
          __typename: 'CiJobsDurationStatistics',
        },
        __typename: 'CiJobsStatistics',
      },
      __typename: 'CiRunnerConnection',
    },
  },
};

export const runnerWaitTimeHistory = {
  data: {
    ciQueueingHistory: {
      timeSeries: [
        {
          time: '2023-09-14T10:00:00Z',
          p99: 99,
          p90: 90,
          p75: 75,
          p50: 50,
          __typename: 'QueueingHistoryTimeSeries',
        },
        {
          time: '2023-09-14T11:00:00Z',
          p99: 98,
          p90: 89,
          p75: 74,
          p50: 49,
          __typename: 'QueueingHistoryTimeSeries',
        },
      ],
    },
  },
};

export const runnerDashboardPath = '/admin/runners/dashboard';

export { allRunnersUpgradeStatusData, mostActiveRunnersData, runnerFailedJobsData };
