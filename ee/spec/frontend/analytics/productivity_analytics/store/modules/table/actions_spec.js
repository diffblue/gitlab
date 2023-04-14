import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/table/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/table/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/table/state';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { mockMergeRequests } from '../../../mock_data';

describe('Productivity analytics table actions', () => {
  let mockedContext;
  let mockedState;
  let mock;

  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';

  const filterParams = {
    days_to_merge: [5],
    sort: 'time_to_merge_asc',
  };

  const pageInfo = {
    page: 1,
    nextPage: 2,
    previousPage: 1,
    perPage: 10,
    total: 50,
    totalPages: 5,
  };

  const headers = {
    'X-Next-Page': pageInfo.nextPage,
    'X-Page': pageInfo.page,
    'X-Per-Page': pageInfo.perPage,
    'X-Prev-Page': pageInfo.previousPage,
    'X-Total': pageInfo.total,
    'X-Total-Pages': pageInfo.totalPages,
  };

  beforeEach(() => {
    mockedContext = {
      dispatch() {},
      rootState: {
        charts: {
          charts: {
            main: {
              selected: [5],
            },
          },
        },
        endpoint: `${TEST_HOST}/analytics/productivity_analytics.json`,
      },
      getters: {
        getFilterParams: () => filterParams,
      },
      rootGetters: {
        // eslint-disable-next-line no-useless-computed-key
        ['filters/getCommonFilterParams']: () => {
          const params = {
            group_id: groupNamespace,
            project_id: projectPath,
          };
          return params;
        },
      },
      state: getInitialState(),
    };

    // testAction looks for rootGetters in state,
    // so they need to be concatenated here.
    mockedState = {
      ...mockedContext.state,
      ...mockedContext.getters,
      ...mockedContext.rootGetters,
      ...mockedContext.rootState,
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchMergeRequests', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(HTTP_STATUS_OK, mockMergeRequests, headers);
      });

      it('calls API with pparams', () => {
        jest.spyOn(axios, 'get');

        actions.fetchMergeRequests(mockedContext);

        expect(axios.get).toHaveBeenCalledWith(mockedState.endpoint, {
          params: {
            group_id: groupNamespace,
            project_id: projectPath,
            days_to_merge: [5],
            sort: 'time_to_merge_asc',
          },
        });
      });

      it('dispatches success with received data', () =>
        testAction(
          actions.fetchMergeRequests,
          null,
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            {
              type: 'receiveMergeRequestsSuccess',
              payload: { data: mockMergeRequests, headers },
            },
          ],
        ));
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches error', async () => {
        await testAction(
          actions.fetchMergeRequests,
          null,
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            {
              type: 'receiveMergeRequestsError',
              payload: new Error('Request failed with status code 500'),
            },
          ],
        );
      });
    });
  });

  describe('requestMergeRequests', () => {
    it('should commit the request mutation', () =>
      testAction(
        actions.requestMergeRequests,
        null,
        mockedContext.state,
        [{ type: types.REQUEST_MERGE_REQUESTS }],
        [],
      ));
  });

  describe('receiveMergeRequestsSuccess', () => {
    it('should commit received data', () =>
      testAction(
        actions.receiveMergeRequestsSuccess,
        { headers, data: mockMergeRequests },
        mockedContext.state,
        [
          {
            type: types.RECEIVE_MERGE_REQUESTS_SUCCESS,
            payload: { pageInfo, mergeRequests: mockMergeRequests },
          },
        ],
        [],
      ));
  });

  describe('receiveMergeRequestsError', () => {
    it('should commit error', () =>
      testAction(
        actions.receiveMergeRequestsError,
        { response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } },
        mockedContext.state,
        [{ type: types.RECEIVE_MERGE_REQUESTS_ERROR, payload: HTTP_STATUS_INTERNAL_SERVER_ERROR }],
        [],
      ));
  });

  describe('setSortField', () => {
    it('should commit setSortField', () =>
      testAction(
        actions.setSortField,
        'time_to_last_commit',
        mockedContext.state,
        [{ type: types.SET_SORT_FIELD, payload: 'time_to_last_commit' }],
        [
          { type: 'setColumnMetric', payload: 'time_to_last_commit' },
          { type: 'fetchMergeRequests' },
        ],
      ));

    it('should not dispatch setColumnMetric when metric is "days_to_merge"', () =>
      testAction(
        actions.setSortField,
        'days_to_merge',
        mockedContext.state,
        [{ type: types.SET_SORT_FIELD, payload: 'days_to_merge' }],
        [{ type: 'fetchMergeRequests' }],
      ));
  });

  describe('toggleSortOrder', () => {
    it('should commit toggleSortOrder', () =>
      testAction(
        actions.toggleSortOrder,
        null,
        mockedContext.state,
        [{ type: types.TOGGLE_SORT_ORDER }],
        [{ type: 'fetchMergeRequests' }],
      ));
  });

  describe('setColumnMetric', () => {
    it('should commit setColumnMetric', () =>
      testAction(
        actions.setColumnMetric,
        'time_to_first_comment',
        mockedContext.state,
        [{ type: types.SET_COLUMN_METRIC, payload: 'time_to_first_comment' }],
        [],
      ));
  });

  describe('setPage', () => {
    it('should commit setPage', () =>
      testAction(
        actions.setPage,
        2,
        mockedContext.state,
        [{ type: types.SET_PAGE, payload: 2 }],
        [{ type: 'fetchMergeRequests' }],
      ));
  });
});
