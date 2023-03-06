import MockAdapter from 'axios-mock-adapter';

import { CHART_TYPES } from 'ee/insights/constants';
import * as actions from 'ee/insights/stores/modules/insights/actions';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';

import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

const ERROR_MESSAGE = 'TEST_ERROR_MESSAGE';

jest.mock('~/alert');

describe('Insights store actions', () => {
  const key = 'bugsPerTeam';
  const chart = {
    title: 'Bugs Per Team',
    type: CHART_TYPES.STACKED_BAR,
    query: {
      name: 'filter_issues_by_label_category',
      filter_label: 'bug',
      category_labels: ['Plan', 'Create', 'Manage'],
      group_by: 'month',
      issuable_type: 'issue',
    },
  };
  const page = {
    title: 'Bugs Charts',
    charts: [chart],
  };
  const configData = {};

  beforeEach(() => {
    configData[key] = page;
  });

  describe('requestConfig', () => {
    it('commits REQUEST_CONFIG', () => {
      return testAction(actions.requestConfig, null, null, [{ type: 'REQUEST_CONFIG' }], []);
    });
  });

  describe('receiveConfigSuccess', () => {
    it('commits RECEIVE_CONFIG_SUCCESS', () => {
      return testAction(
        actions.receiveConfigSuccess,
        [configData],
        null,
        [{ type: 'RECEIVE_CONFIG_SUCCESS', payload: [configData] }],
        [],
      );
    });
  });

  describe('receiveConfigError', () => {
    it('commits RECEIVE_CONFIG_ERROR and shows alert message', async () => {
      await testAction(
        actions.receiveConfigError,
        ERROR_MESSAGE,
        null,
        [{ type: 'RECEIVE_CONFIG_ERROR' }],
        [],
      );

      expect(createAlert).toHaveBeenCalledWith({
        message: `There was an error fetching configuration for charts: ${ERROR_MESSAGE}`,
      });
    });

    it('shows `Unknown Error` alert when error message is falsy', async () => {
      await testAction(
        actions.receiveConfigError,
        null,
        null,
        expect.any(Array),
        expect.any(Array),
      );

      expect(createAlert).toHaveBeenCalledWith({
        message: `There was an error fetching configuration for charts: Unknown Error`,
      });
    });
  });

  describe('fetchConfigData', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success calls', () => {
      beforeEach(() => {
        mock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, configData);
      });

      it('calls requestConfig and receiveConfigSuccess', () => {
        return testAction(
          actions.fetchConfigData,
          TEST_HOST,
          {},
          [],
          [{ type: 'requestConfig' }, { type: 'receiveConfigSuccess', payload: configData }],
        );
      });
    });

    describe('failed calls', () => {
      beforeEach(() => {
        mock.onGet(TEST_HOST).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, { message: ERROR_MESSAGE });
      });

      it('calls receiveConfigError upon error from service', () => {
        return testAction(
          actions.fetchConfigData,
          TEST_HOST,
          {},
          [],
          [{ type: 'requestConfig' }, { type: 'receiveConfigError', payload: ERROR_MESSAGE }],
        );
      });
    });

    describe('success calls with null data', () => {
      beforeEach(() => {
        mock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, null);
      });

      it('calls receiveConfigError upon null config data returned', () => {
        return testAction(
          actions.fetchConfigData,
          TEST_HOST,
          {},
          [],
          [{ type: 'requestConfig' }, { type: 'receiveConfigError' }],
        );
      });
    });
  });

  describe('receiveChartDataSuccess', () => {
    const chartData = { type: CHART_TYPES.BAR, data: {} };

    it('commits RECEIVE_CHART_SUCCESS', () => {
      return testAction(
        actions.receiveChartDataSuccess,
        { chart, data: chartData },
        null,
        [
          {
            type: 'RECEIVE_CHART_SUCCESS',
            payload: { chart, data: chartData },
          },
        ],
        [],
      );
    });
  });

  describe('receiveChartDataError', () => {
    const error = 'myError';

    it('commits RECEIVE_CHART_ERROR', () => {
      return testAction(
        actions.receiveChartDataError,
        { chart, error },
        null,
        [
          {
            type: 'RECEIVE_CHART_ERROR',
            payload: { chart, error },
          },
        ],
        [],
      );
    });
  });

  describe('fetchChartData', () => {
    let mock;
    let dispatch;
    const payload = { endpoint: `${TEST_HOST}/query`, chart };

    const chartData = {
      labels: ['January', 'February'],
      datasets: [
        {
          label: 'Dataset 1',
          fill: true,
          backgroundColor: ['rgba(255, 99, 132)'],
          data: [1],
        },
        {
          label: 'Dataset 2',
          fill: true,
          backgroundColor: ['rgba(54, 162, 235)'],
          data: [2],
        },
      ],
    };

    beforeEach(() => {
      dispatch = jest.fn().mockName('dispatch');
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('successful request', () => {
      beforeEach(() => {
        mock.onPost(`${TEST_HOST}/query`, chart).reply(HTTP_STATUS_OK, chartData);
      });

      it('calls receiveChartDataSuccess with chart data', () => {
        const context = {
          dispatch,
        };

        return actions.fetchChartData(context, payload).then(() => {
          expect(dispatch.mock.calls[0]).toEqual([
            'receiveChartDataSuccess',
            { chart, data: chartData },
          ]);
        });
      });
    });

    describe('failed request', () => {
      beforeEach(() => {
        mock.onPost(`${TEST_HOST}/query`, chart).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('calls receiveChartDataError with error message', () => {
        const context = {
          dispatch,
        };

        return actions.fetchChartData(context, payload).then(() => {
          expect(dispatch.mock.calls[0]).toEqual([
            'receiveChartDataError',
            { chart, error: 'There was an error gathering the chart data' },
          ]);
        });
      });
    });
  });

  describe('setActiveTab', () => {
    let state;

    beforeEach(() => {
      state = { configData };
    });

    it('commits SET_ACTIVE_TAB and SET_ACTIVE_PAGE', () => {
      return testAction(
        actions.setActiveTab,
        key,
        state,
        [
          { type: 'SET_ACTIVE_TAB', payload: key },
          { type: 'SET_ACTIVE_PAGE', payload: page },
        ],
        [],
      );
    });

    it('does not mutate with no configData', () => {
      state = { configData: null };

      testAction(actions.setActiveTab, key, state, [], []);
    });

    it('does not mutate with no matching tab', () => {
      testAction(actions.setActiveTab, 'invalidTab', state, [], []);
    });
  });

  describe('initChartData', () => {
    it('commits INIT_CHART_DATA', () => {
      const keys = ['a', 'b'];

      return testAction(
        actions.initChartData,
        keys,
        null,
        [{ type: 'INIT_CHART_DATA', payload: keys }],
        [],
      );
    });
  });
});
