import { DEPLOYMENT_FREQUENCY_METRIC_TYPE } from 'ee/api/dora_api';
import { defaultClient } from './client';
import {
  ERROR_FORECAST_FAILED,
  ERROR_FORECAST_UNAVAILABLE,
  FORECAST_RESPONSE_STATUS_UNAVAILABLE,
} from './constants';
import BuildForecastMutation from './build_forecast.mutation.graphql';

export const buildForecast = async (contextId, forecastHorizon) => {
  const results = await defaultClient.mutate({
    mutation: BuildForecastMutation,
    variables: { forecastType: DEPLOYMENT_FREQUENCY_METRIC_TYPE, contextId, forecastHorizon },
  });

  if (!results.data?.buildForecast?.forecast) {
    throw new Error(ERROR_FORECAST_FAILED);
  }

  const {
    data: {
      buildForecast: { forecast },
    },
  } = results;

  if (forecast.status === FORECAST_RESPONSE_STATUS_UNAVAILABLE) {
    throw new Error(ERROR_FORECAST_UNAVAILABLE);
  }

  return forecast?.values?.nodes;
};
