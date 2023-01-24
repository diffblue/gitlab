import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { tableSortOrder } from 'ee/analytics/productivity_analytics/constants';
import * as types from 'ee/analytics/productivity_analytics/store/modules/table/mutation_types';
import mutations from 'ee/analytics/productivity_analytics/store/modules/table/mutations';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/table/state';
import { mockMergeRequests } from '../../../mock_data';

describe('Productivity analytics table mutations', () => {
  let state;

  const pageInfo = {
    a: 1,
    b: 2,
    c: 3,
  };

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.REQUEST_MERGE_REQUESTS, () => {
    it('sets isLoadingTable to true', () => {
      mutations[types.REQUEST_MERGE_REQUESTS](state);

      expect(state.isLoadingTable).toBe(true);
    });
  });

  describe(types.RECEIVE_MERGE_REQUESTS_SUCCESS, () => {
    it('updates table with data', () => {
      mutations[types.RECEIVE_MERGE_REQUESTS_SUCCESS](state, {
        pageInfo,
        mergeRequests: mockMergeRequests,
      });

      expect(state.isLoadingTable).toBe(false);
      expect(state.errorCode).toBe(null);
      expect(state.mergeRequests).toEqual(mockMergeRequests);
      expect(state.pageInfo).toEqual(pageInfo);
    });
  });

  describe(types.RECEIVE_MERGE_REQUESTS_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_MERGE_REQUESTS_ERROR](state, HTTP_STATUS_INTERNAL_SERVER_ERROR);
    });

    it('sets errorCode to 500', () => {
      expect(state.isLoadingTable).toBe(false);
      expect(state.errorCode).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    });

    it('clears data', () => {
      expect(state.isLoadingTable).toBe(false);
      expect(state.mergeRequests).toEqual([]);
      expect(state.pageInfo).toEqual({});
    });
  });

  describe(types.SET_SORT_FIELD, () => {
    it('sets sortField to "time_to_last_commit"', () => {
      const sortField = 'time_to_last_commit';
      mutations[types.SET_SORT_FIELD](state, sortField);

      expect(state.sortField).toBe(sortField);
    });
  });

  describe(types.TOGGLE_SORT_ORDER, () => {
    it('sets sortOrder "asc" when currently "desc"', () => {
      state.sortOrder = tableSortOrder.desc.value;

      mutations[types.TOGGLE_SORT_ORDER](state);

      expect(state.sortOrder).toBe(tableSortOrder.asc.value);
    });

    it('sets sortOrder "desc" when currently "asc"', () => {
      state.sortOrder = tableSortOrder.asc.value;

      mutations[types.TOGGLE_SORT_ORDER](state);

      expect(state.sortOrder).toBe(tableSortOrder.desc.value);
    });
  });

  describe(types.SET_COLUMN_METRIC, () => {
    it('sets columnMetric to "time_to_first_comment"', () => {
      const columnMetric = 'time_to_first_comment';
      mutations[types.SET_COLUMN_METRIC](state, columnMetric);

      expect(state.columnMetric).toBe(columnMetric);
    });
  });
});
