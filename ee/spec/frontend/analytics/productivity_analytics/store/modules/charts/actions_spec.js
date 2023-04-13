import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/charts/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/charts/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/charts/state';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { mockHistogramData, mockScatterplotData } from '../../../mock_data';

jest.mock('ee/analytics/productivity_analytics/utils', () => ({
  transformScatterData: jest
    .fn()
    .mockImplementation(() => [[{ merged_at: '2019-09-01T00:00:000Z', metric: 10 }]]),
}));

describe('Productivity analytics chart actions', () => {
  let mockedContext;
  let mockedState;
  let mock;

  const chartKey = chartKeys.main;
  const globalParams = {
    group_id: 'gitlab-org',
    project_id: 'gitlab-org/gitlab-test',
  };

  beforeEach(() => {
    mockedContext = {
      dispatch() {},
      rootState: {
        endpoint: `${TEST_HOST}/analytics/productivity_analytics.json`,
        filters: {
          startDate: new Date('2019-09-01'),
          endDate: new Date('2091-09-05'),
        },
      },
      getters: {
        getFilterParams: () => globalParams,
      },
      state: getInitialState(),
    };

    // testAction looks for rootGetters in state,
    // so they need to be concatenated here.
    mockedState = {
      ...mockedContext.state,
      ...mockedContext.getters,
      ...mockedContext.rootState,
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchChartData', () => {
    describe('when chart is enabled', () => {
      describe('success', () => {
        describe('histogram charts', () => {
          beforeEach(() => {
            mock.onGet(mockedState.endpoint).replyOnce(HTTP_STATUS_OK, mockHistogramData);
          });

          it('calls API with params', () => {
            jest.spyOn(axios, 'get');

            actions.fetchChartData(mockedContext, chartKey);

            expect(axios.get).toHaveBeenCalledWith(mockedState.endpoint, { params: globalParams });
          });

          it('dispatches success with received data', () =>
            testAction(
              actions.fetchChartData,
              chartKey,
              mockedState,
              [],
              [
                { type: 'requestChartData', payload: chartKey },
                {
                  type: 'receiveChartDataSuccess',
                  payload: expect.objectContaining({ chartKey, data: mockHistogramData }),
                },
              ],
            ));
        });

        describe('scatterplot chart', () => {
          beforeEach(() => {
            mock.onGet(mockedState.endpoint).replyOnce(HTTP_STATUS_OK, mockScatterplotData);
          });

          it('dispatches success with received data and transformedData', async () => {
            await testAction(
              actions.fetchChartData,
              chartKeys.scatterplot,
              mockedState,
              [],
              [
                { type: 'requestChartData', payload: chartKeys.scatterplot },
                {
                  type: 'receiveChartDataSuccess',
                  payload: {
                    chartKey: chartKeys.scatterplot,
                    data: mockScatterplotData,
                    transformedData: [[{ merged_at: '2019-09-01T00:00:000Z', metric: 10 }]],
                  },
                },
              ],
            );
          });
        });
      });

      describe('error', () => {
        beforeEach(() => {
          mock.onGet(mockedState.endpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        });

        it('dispatches error', async () => {
          await testAction(
            actions.fetchChartData,
            chartKey,
            mockedState,
            [],
            [
              {
                type: 'requestChartData',
                payload: chartKey,
              },
              {
                type: 'receiveChartDataError',
                payload: {
                  chartKey,
                  error: new Error('Request failed with status code 500'),
                },
              },
            ],
          );
        });
      });
    });
  });

  describe('requestChartData', () => {
    it('should commit the request mutation', async () => {
      await testAction(
        actions.requestChartData,
        chartKey,
        mockedContext.state,
        [{ type: types.REQUEST_CHART_DATA, payload: chartKey }],
        [],
      );
    });

    describe('when chart is disabled', () => {
      const disabledChartKey = chartKeys.scatterplot;
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(HTTP_STATUS_OK);
        mockedState.charts[disabledChartKey].enabled = false;
      });

      it('does not dispatch the requestChartData action', async () => {
        await testAction(actions.fetchChartData, disabledChartKey, mockedState, [], []);
      });

      it('does not call the API', () => {
        actions.fetchChartData(mockedContext, disabledChartKey);
        jest.spyOn(axios, 'get');
        expect(axios.get).not.toHaveBeenCalled();
      });
    });
  });

  describe('receiveChartDataSuccess', () => {
    it('should commit received data', async () => {
      await testAction(
        actions.receiveChartDataSuccess,
        { chartKey, data: mockHistogramData },
        mockedContext.state,
        [
          {
            type: types.RECEIVE_CHART_DATA_SUCCESS,
            payload: { chartKey, data: mockHistogramData, transformedData: null },
          },
        ],
        [],
      );
    });
  });

  describe('receiveChartDataError', () => {
    it('should commit error', async () => {
      const error = { response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } };
      await testAction(
        actions.receiveChartDataError,
        { chartKey, error },
        mockedContext.state,
        [
          {
            type: types.RECEIVE_CHART_DATA_ERROR,
            payload: {
              chartKey,
              status: HTTP_STATUS_INTERNAL_SERVER_ERROR,
            },
          },
        ],
        [],
      );
    });
  });

  describe('fetchSecondaryChartData', () => {
    it('dispatches fetchChartData for all chart types except for the main chart', async () => {
      await testAction(
        actions.fetchSecondaryChartData,
        null,
        mockedContext.state,
        [],
        [
          { type: 'fetchChartData', payload: chartKeys.timeBasedHistogram },
          { type: 'fetchChartData', payload: chartKeys.commitBasedHistogram },
          { type: 'fetchChartData', payload: chartKeys.scatterplot },
        ],
      );
    });
  });

  describe('setMetricType', () => {
    const metricType = 'time_to_merge';

    it('should commit metricType', async () => {
      await testAction(
        actions.setMetricType,
        { chartKey, metricType },
        mockedContext.state,
        [{ type: types.SET_METRIC_TYPE, payload: { chartKey, metricType } }],
        [{ type: 'fetchChartData', payload: chartKey }],
      );
    });
  });

  describe('updateSelectedItems', () => {
    it('should commit selected chart item and dispatch fetchSecondaryChartData and setPage', async () => {
      await testAction(
        actions.updateSelectedItems,
        { chartKey, item: 5 },
        mockedContext.state,
        [{ type: types.UPDATE_SELECTED_CHART_ITEMS, payload: { chartKey, item: 5 } }],
        [{ type: 'fetchSecondaryChartData' }, { type: 'table/setPage', payload: 0 }],
      );
    });
  });

  describe('resetMainChartSelection', () => {
    describe('when skipReload is false (by default)', () => {
      it('should commit selected chart item and dispatch fetchSecondaryChartData and setPage', async () => {
        await testAction(
          actions.resetMainChartSelection,
          null,
          mockedContext.state,
          [{ type: types.UPDATE_SELECTED_CHART_ITEMS, payload: { chartKey, item: null } }],
          [{ type: 'fetchSecondaryChartData' }, { type: 'table/setPage', payload: 0 }],
        );
      });
    });

    describe('when skipReload is true', () => {
      it('should commit selected chart and it should not dispatch any further actions', async () => {
        await testAction(
          actions.resetMainChartSelection,
          true,
          mockedContext.state,
          [
            {
              type: types.UPDATE_SELECTED_CHART_ITEMS,
              payload: { chartKey: chartKeys.main, item: null },
            },
          ],
          [],
        );
      });
    });
  });

  describe('setChartEnabled', () => {
    it('should commit enabled state', async () => {
      await testAction(
        actions.setChartEnabled,
        { chartKey: chartKeys.scatterplot, isEnabled: false },
        mockedContext.state,
        [
          {
            type: types.SET_CHART_ENABLED,
            payload: { chartKey: chartKeys.scatterplot, isEnabled: false },
          },
        ],
        [],
      );
    });
  });
});
