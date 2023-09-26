import * as types from 'ee/geo_replicable/store/mutation_types';
import mutations from 'ee/geo_replicable/store/mutations';
import createState from 'ee/geo_replicable/store/state';
import { FILTER_OPTIONS } from 'ee/geo_replicable/constants';
import {
  MOCK_GRAPHQL_REGISTRY,
  MOCK_REPLICABLE_TYPE,
  MOCK_BASIC_GRAPHQL_DATA,
  MOCK_GRAPHQL_PAGINATION_DATA,
} from '../mock_data';

describe('GeoReplicable Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState({
      replicableType: MOCK_REPLICABLE_TYPE,
      graphqlFieldName: MOCK_GRAPHQL_REGISTRY,
    });
  });

  describe('SET_STATUS_FILTER', () => {
    const testValue = FILTER_OPTIONS[2].value;

    beforeEach(() => {
      state.statusFilter = FILTER_OPTIONS[1].value;
      state.paginationData.page = 2;

      mutations[types.SET_STATUS_FILTER](state, testValue);
    });

    it('sets the statusFilter state key', () => {
      expect(state.statusFilter).toBe(testValue);
    });

    it('resets the page to 1', () => {
      expect(state.paginationData.page).toBe(1);
    });
  });

  describe('SET_SEARCH', () => {
    const testValue = 'test search';

    beforeEach(() => {
      state.paginationData.page = 2;

      mutations[types.SET_SEARCH](state, testValue);
    });

    it('sets the searchFilter state key', () => {
      expect(state.searchFilter).toBe(testValue);
    });

    it('resets the page to 1', () => {
      expect(state.paginationData.page).toBe(1);
    });
  });

  describe('REQUEST_REPLICABLE_ITEMS', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_REPLICABLE_ITEMS](state);
      expect(state.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_REPLICABLE_ITEMS_SUCCESS', () => {
    let mockData = {};
    let mockPaginationData = {};

    beforeEach(() => {
      mockData = MOCK_BASIC_GRAPHQL_DATA;
      mockPaginationData = MOCK_GRAPHQL_PAGINATION_DATA;
    });

    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_REPLICABLE_ITEMS_SUCCESS](state, {
        data: mockData,
        pagination: mockPaginationData,
      });
      expect(state.isLoading).toBe(false);
    });

    it('sets replicableItems array with data', () => {
      mutations[types.RECEIVE_REPLICABLE_ITEMS_SUCCESS](state, {
        data: mockData,
        pagination: mockPaginationData,
      });
      expect(state.replicableItems).toBe(mockData);
    });

    it('sets hasNextPage, hasPreviousPage, startCursor, and endCursor', () => {
      mutations[types.RECEIVE_REPLICABLE_ITEMS_SUCCESS](state, {
        data: mockData,
        pagination: mockPaginationData,
      });
      expect(state.paginationData.hasNextPage).toBe(mockPaginationData.hasNextPage);
      expect(state.paginationData.hasPreviousPage).toBe(mockPaginationData.hasPreviousPage);
      expect(state.paginationData.startCursor).toBe(mockPaginationData.startCursor);
      expect(state.paginationData.endCursor).toBe(mockPaginationData.endCursor);
    });
  });

  describe('RECEIVE_REPLICABLE_ITEMS_ERROR', () => {
    let mockData = {};

    beforeEach(() => {
      mockData = MOCK_BASIC_GRAPHQL_DATA;
    });

    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_REPLICABLE_ITEMS_ERROR](state);
      expect(state.isLoading).toBe(false);
    });

    it('resets replicableItems array', () => {
      state.replicableItems = mockData.data;

      mutations[types.RECEIVE_REPLICABLE_ITEMS_ERROR](state);
      expect(state.replicableItems).toStrictEqual([]);
    });

    it('resets pagination data', () => {
      mutations[types.RECEIVE_REPLICABLE_ITEMS_ERROR](state);
      expect(state.paginationData).toStrictEqual({});
    });
  });

  describe.each`
    mutation                                                | loadingBefore | loadingAfter
    ${types.REQUEST_INITIATE_ALL_REPLICABLE_ACTION}         | ${false}      | ${true}
    ${types.RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_SUCCESS} | ${true}       | ${false}
    ${types.RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_ERROR}   | ${true}       | ${false}
    ${types.REQUEST_INITIATE_REPLICABLE_ACTION}             | ${false}      | ${true}
    ${types.RECEIVE_INITIATE_REPLICABLE_ACTION_SUCCESS}     | ${true}       | ${false}
    ${types.RECEIVE_INITIATE_REPLICABLE_ACTION_ERROR}       | ${true}       | ${false}
  `(`Sync Mutations:`, ({ mutation, loadingBefore, loadingAfter }) => {
    describe(`${mutation}`, () => {
      it(`sets isLoading to ${loadingAfter}`, () => {
        state.isLoading = loadingBefore;

        mutations[mutation](state);
        expect(state.isLoading).toBe(loadingAfter);
      });
    });
  });
});
