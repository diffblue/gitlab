export const mockResultSet = {
  seriesNames: () => [
    {
      title: 'pageview, Jitsu Count',
      key: 'pageview,Jitsu.count',
      yValues: ['pageview', 'Jitsu.count'],
    },
  ],
  chartPivot: () => [
    {
      x: '2022-11-09T00:00:00.000',
      xValues: ['2022-11-09T00:00:00.000'],
      'pageview,Jitsu.count': 55,
    },
    {
      x: '2022-11-10T00:00:00.000',
      xValues: ['2022-11-10T00:00:00.000'],
      'pageview,Jitsu.count': 14,
    },
  ],
};
