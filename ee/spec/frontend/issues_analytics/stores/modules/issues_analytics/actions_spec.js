import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/issues_analytics/stores/modules/issue_analytics/actions';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('Issue analytics store actions', () => {
  describe('setFilters', () => {
    it('commits SET_FILTERS', () => {
      testAction(actions.setFilters, null, null, [{ type: 'SET_FILTERS', payload: null }], []);
    });
  });

  describe('setLoadingState', () => {
    it('commits SET_LOADING_STATE', () => {
      testAction(
        actions.setLoadingState,
        true,
        null,
        [{ type: 'SET_LOADING_STATE', payload: true }],
        [],
      );
    });
  });

  describe('fetchChartData', () => {
    let mock;
    let commit;
    let dispatch;
    const chartData = { '2017-11': 0, '2017-12': 2 };

    beforeEach(() => {
      dispatch = jest.fn().mockName('dispatch');
      commit = jest.fn().mockName('commit');
      mock = new MockAdapter(axios);

      mock.onGet().reply(HTTP_STATUS_OK, chartData);
    });

    afterEach(() => {
      mock.restore();
    });

    it('commits SET_CHART_DATA with chart data', () => {
      const getters = { appliedFilters: { hello: 'world' } };
      const context = {
        dispatch,
        getters,
        commit,
      };

      return actions.fetchChartData(context, TEST_HOST).then(() => {
        expect(dispatch.mock.calls[0]).toEqual(['setLoadingState', true]);
        expect(commit).toHaveBeenCalledWith('SET_CHART_DATA', chartData);
        expect(dispatch.mock.calls[1]).toEqual(['setLoadingState', false]);
      });
    });
  });
});
