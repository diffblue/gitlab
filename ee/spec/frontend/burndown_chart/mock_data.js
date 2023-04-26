export const day1 = {
  __typename: 'BurnupChartDailyTotals',
  date: '2020-04-08',
  completedCount: 0,
  completedWeight: 0,
  scopeCount: 10,
  scopeWeight: 20,
};

export const day2 = {
  __typename: 'BurnupChartDailyTotals',
  date: '2020-04-09',
  completedCount: 1,
  completedWeight: 1,
  scopeCount: 11,
  scopeWeight: 20,
};

export const day3 = {
  __typename: 'BurnupChartDailyTotals',
  date: '2020-04-10',
  completedCount: 2,
  completedWeight: 4,
  scopeCount: 11,
  scopeWeight: 22,
};

export const day4 = {
  __typename: 'BurnupChartDailyTotals',
  date: '2020-04-11',
  completedCount: 3,
  completedWeight: 5,
  scopeCount: 11,
  scopeWeight: 22,
};

export const legacyBurndownEvents = [
  {
    action: 'created',
    created_at: day1.date,
    weight: 2,
  },
  {
    action: 'created',
    created_at: day2.date,
    weight: 1,
  },
  {
    action: 'created',
    created_at: day3.date,
    weight: 1,
  },
  {
    action: 'closed',
    created_at: day4.date,
    weight: 2,
  },
];

export const getBurnupQueryIterationSuccess = (days) => ({
  data: {
    iteration: {
      __typename: 'Iteration',
      id: 'gid://gitlab/Iteration/139072',
      title: null,
      report: {
        __typename: 'TimeboxReport',
        burnupTimeSeries: days,
        stats: {
          __typename: 'TimeReportStats',
          total: { __typename: 'TimeboxMetrics', count: 12, weight: 15 },
          complete: { __typename: 'TimeboxMetrics', count: 2, weight: 3 },
          incomplete: { __typename: 'TimeboxMetrics', count: 10, weight: 12 },
        },
      },
    },
  },
});
