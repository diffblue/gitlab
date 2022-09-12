import * as types from 'ee/geo_replicable/store/mutation_types';
import mutations from 'ee/geo_replicable/store/mutations';
import createState from 'ee/geo_replicable/store/state';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_REPLICABLE_TYPE,
  MOCK_RESTFUL_PAGINATION_DATA,
  MOCK_GRAPHQL_PAGINATION_DATA,
} from '../mock_data';

describe('GeoReplicable Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null });
  });

  describe('SET_FILTER', () => {
    const testValue = 2;

    beforeEach(() => {
      state.currentFilterIndex = 1;
      state.paginationData.page = 2;

      mutations[types.SET_FILTER](state, testValue);
    });

    it('sets the currentFilterIndex state key', () => {
      expect(state.currentFilterIndex).toEqual(testValue);
    });

    it('resets the page to 1', () => {
      expect(state.paginationData.page).toEqual(1);
    });
  });

  describe('SET_SEARCH', () => {
    const testValue = 'test search';

    beforeEach(() => {
      state.paginationData.page = 2;

      mutations[types.SET_SEARCH](state, testValue);
    });

    it('sets the searchFilter state key', () => {
      expect(state.searchFilter).toEqual(testValue);
    });

    it('resets the page to 1', () => {
      expect(state.paginationData.page).toEqual(1);
    });
  });

  describe('SET_PAGE', () => {
    it('sets the page state key', () => {
      const testValue = 2;

      mutations[types.SET_PAGE](state, testValue);
      expect(state.paginationData.page).toEqual(testValue);
    });
  });

  describe('REQUEST_REPLICABLE_ITEMS', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_REPLICABLE_ITEMS](state);
      expect(state.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_REPLICABLE_ITEMS_SUCCESS', () => {
    let mockData = {};
    let mockPaginationData = {};

    describe('with RESTful pagination', () => {
      beforeEach(() => {
        mockData = MOCK_BASIC_FETCH_DATA_MAP;
        mockPaginationData = MOCK_RESTFUL_PAGINATION_DATA;
      });

      it('sets isLoading to false', () => {
        state.isLoading = true;

        mutations[types.RECEIVE_REPLICABLE_ITEMS_SUCCESS](state, {
          data: mockData,
          pagination: mockPaginationData,
        });
        expect(state.isLoading).toEqual(false);
      });

      it('sets replicableItems array with data', () => {
        mutations[types.RECEIVE_REPLICABLE_ITEMS_SUCCESS](state, {
          data: mockData,
          pagination: mockPaginationData,
        });
        expect(state.replicableItems).toBe(mockData);
      });

      it('sets perPage and total', () => {
        mutations[types.RECEIVE_REPLICABLE_ITEMS_SUCCESS](state, {
          data: mockData,
          pagination: mockPaginationData,
        });
        expect(state.paginationData.perPage).toEqual(mockPaginationData.perPage);
        expect(state.paginationData.total).toEqual(mockPaginationData.total);
      });
    });

    describe('with GraphQL pagination', () => {
      beforeEach(() => {
        mockData = MOCK_BASIC_FETCH_DATA_MAP;
        mockPaginationData = MOCK_GRAPHQL_PAGINATION_DATA;
      });

      it('sets isLoading to false', () => {
        state.isLoading = true;

        mutations[types.RECEIVE_REPLICABLE_ITEMS_SUCCESS](state, {
          data: mockData,
          pagination: mockPaginationData,
        });
        expect(state.isLoading).toEqual(false);
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
        expect(state.paginationData.hasNextPage).toEqual(mockPaginationData.hasNextPage);
        expect(state.paginationData.hasPreviousPage).toEqual(mockPaginationData.hasPreviousPage);
        expect(state.paginationData.startCursor).toEqual(mockPaginationData.startCursor);
        expect(state.paginationData.endCursor).toEqual(mockPaginationData.endCursor);
      });
    });
  });

  describe('RECEIVE_REPLICABLE_ITEMS_ERROR', () => {
    let mockData = {};

    beforeEach(() => {
      mockData = MOCK_BASIC_FETCH_DATA_MAP;
    });

    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_REPLICABLE_ITEMS_ERROR](state);
      expect(state.isLoading).toEqual(false);
    });

    it('resets replicableItems array', () => {
      state.replicableItems = mockData.data;

      mutations[types.RECEIVE_REPLICABLE_ITEMS_ERROR](state);
      expect(state.replicableItems).toEqual([]);
    });

    it('resets pagination data', () => {
      mutations[types.RECEIVE_REPLICABLE_ITEMS_ERROR](state);
      expect(state.paginationData).toEqual({});
    });
  });

  describe.each`
    mutation                                               | loadingBefore | loadingAfter
    ${types.REQUEST_INITIATE_ALL_REPLICABLE_SYNCS}         | ${false}      | ${true}
    ${types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS} | ${true}       | ${false}
    ${types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR}   | ${true}       | ${false}
    ${types.REQUEST_INITIATE_REPLICABLE_SYNC}              | ${false}      | ${true}
    ${types.RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS}      | ${true}       | ${false}
    ${types.RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR}        | ${true}       | ${false}
  `(`Sync Mutations:`, ({ mutation, loadingBefore, loadingAfter }) => {
    describe(`${mutation}`, () => {
      it(`sets isLoading to ${loadingAfter}`, () => {
        state.isLoading = loadingBefore;

        mutations[mutation](state);
        expect(state.isLoading).toEqual(loadingAfter);
      });
    });
  });
});
