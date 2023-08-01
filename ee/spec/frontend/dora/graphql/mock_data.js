export const forecastValues = [
  { date: '2023-07-21', value: 20.0, __typename: 'ForecastDatapoint' },
  { date: '2023-07-22', value: 27.0, __typename: 'ForecastDatapoint' },
  { date: '2023-07-23', value: 15.0, __typename: 'ForecastDatapoint' },
];

const forecastUnavailable = {
  status: 'UNAVAILABLE',
  values: {
    nodes: [],
    __typename: 'ForecastDatapointConnection',
  },
  __typename: 'Forecast',
};

const forecastReady = {
  status: 'READY',
  values: {
    nodes: forecastValues,
    __typename: 'ForecastDatapointConnection',
  },
  __typename: 'Forecast',
};

export const buildForecastReadyMutationResponse = {
  data: {
    buildForecast: {
      forecast: forecastReady,
      __typename: 'BuildForecastPayload',
    },
  },
};

export const buildForecastUnavailableMutationResponse = {
  data: {
    buildForecast: {
      forecast: forecastUnavailable,
      __typename: 'BuildForecastPayload',
    },
  },
};
