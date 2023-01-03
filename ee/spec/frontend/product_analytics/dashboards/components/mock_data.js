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
  tableColumns: () => [
    {
      key: 'Jitsu.utcTime.day',
      title: 'Jitsu Utc Time',
      shortTitle: 'Utc Time',
      type: 'time',
      dataIndex: 'Jitsu.utcTime.day',
    },
    {
      key: 'Jitsu.eventType',
      title: 'Jitsu Event Type',
      shortTitle: 'Event Type',
      type: 'string',
      dataIndex: 'Jitsu.eventType',
    },
    {
      key: 'Jitsu.count',
      type: 'number',
      dataIndex: 'Jitsu.count',
      title: 'Jitsu Count',
      shortTitle: 'Count',
    },
  ],
  tablePivot: () => [
    {
      'Jitsu.utcTime.day': '2022-11-09T00:00:00.000',
      'Jitsu.eventType': 'pageview',
      'Jitsu.count': '55',
    },
    {
      'Jitsu.utcTime.day': '2022-11-10T00:00:00.000',
      'Jitsu.eventType': 'pageview',
      'Jitsu.count': '14',
    },
  ],
  rawData: () => [
    {
      'Jitsu.userLanguage': 'en-US',
      'Jitsu.count': '36',
      'Jitsu.url': 'https://example.com/us',
    },
    {
      'Jitsu.userLanguage': 'es-ES',
      'Jitsu.count': '60',
      'Jitsu.url': 'https://example.com/es',
    },
  ],
};

export const mockCountResultSet = (count) => ({
  rawData: () => [
    {
      'Jitsu.count': count,
    },
  ],
});
