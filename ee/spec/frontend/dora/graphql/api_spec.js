import { defaultClient } from 'ee/dora/graphql/client';
import { buildForecast } from 'ee/dora/graphql/api';
import buildForecastMutation from 'ee/dora/graphql/build_forecast.mutation.graphql';
import {
  forecastValues,
  buildForecastReadyMutationResponse,
  buildForecastUnavailableMutationResponse,
} from './mock_data';

describe('Dora Graphql API', () => {
  describe('BuildForecastMutation', () => {
    const contextId = 'gid://gitlab/project/1';
    const forecastHorizon = 3;
    const forecastType = 'deployment_frequency';

    const variables = { contextId, forecastHorizon, forecastType };

    it('returns forecasted data on success', async () => {
      jest.spyOn(defaultClient, 'mutate').mockResolvedValue(buildForecastReadyMutationResponse);
      const result = await buildForecast(contextId, forecastHorizon);

      expect(defaultClient.mutate).toHaveBeenCalledWith({
        mutation: buildForecastMutation,
        variables,
      });
      expect(result).toEqual(forecastValues);
    });

    it('throws `ERROR_FORECAST_FAILED` if there is no data returned', async () => {
      jest.spyOn(defaultClient, 'mutate').mockResolvedValue({});

      await expect(buildForecast(contextId, forecastHorizon)).rejects.toThrow(
        'ERROR_FORECAST_FAILED',
      );
    });

    it('throws `ERROR_FORECAST_UNAVAILABLE` if the request status is `FORECAST_RESPONSE_STATUS_UNAVAILABLE`', async () => {
      jest
        .spyOn(defaultClient, 'mutate')
        .mockResolvedValue(buildForecastUnavailableMutationResponse);

      await expect(buildForecast(contextId, forecastHorizon)).rejects.toThrow(
        'ERROR_FORECAST_UNAVAILABLE',
      );
    });
  });
});
