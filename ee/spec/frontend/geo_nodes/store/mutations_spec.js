import * as types from 'ee/geo_nodes/store/mutation_types';
import mutations from 'ee/geo_nodes/store/mutations';
import createState from 'ee/geo_nodes/store/state';
import { MOCK_PRIMARY_VERSION, MOCK_REPLICABLE_TYPES, MOCK_NODES } from '../mock_data';

describe('GeoNodes Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState({
      primaryVersion: MOCK_PRIMARY_VERSION.version,
      primaryRevision: MOCK_PRIMARY_VERSION.revision,
      replicableTypes: MOCK_REPLICABLE_TYPES,
    });
  });

  describe('REQUEST_NODES', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_NODES](state);

      expect(state.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_NODES_SUCCESS', () => {
    beforeEach(() => {
      state.isLoading = true;
    });

    it('sets nodes and ends loading', () => {
      mutations[types.RECEIVE_NODES_SUCCESS](state, MOCK_NODES);

      expect(state.isLoading).toBe(false);
      expect(state.nodes).toEqual(MOCK_NODES);
    });
  });

  describe('RECEIVE_NODES_ERROR', () => {
    beforeEach(() => {
      state.isLoading = true;
      state.nodes = MOCK_NODES;
    });

    it('resets state', () => {
      mutations[types.RECEIVE_NODES_ERROR](state);

      expect(state.isLoading).toBe(false);
      expect(state.nodes).toEqual([]);
    });
  });

  describe('STAGE_NODE_REMOVAL', () => {
    it('sets nodeToBeRemoved to node id', () => {
      mutations[types.STAGE_NODE_REMOVAL](state, 1);

      expect(state.nodeToBeRemoved).toBe(1);
    });
  });

  describe('UNSTAGE_NODE_REMOVAL', () => {
    beforeEach(() => {
      state.nodeToBeRemoved = 1;
    });

    it('sets nodeToBeRemoved to null', () => {
      mutations[types.UNSTAGE_NODE_REMOVAL](state);

      expect(state.nodeToBeRemoved).toBe(null);
    });
  });

  describe('REQUEST_NODE_REMOVAL', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_NODE_REMOVAL](state);

      expect(state.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_NODE_REMOVAL_SUCCESS', () => {
    beforeEach(() => {
      state.isLoading = true;
      state.nodes = [{ id: 1 }, { id: 2 }];
      state.nodeToBeRemoved = 1;
    });

    it('removes node, clears nodeToBeRemoved, and ends loading', () => {
      mutations[types.RECEIVE_NODE_REMOVAL_SUCCESS](state);

      expect(state.isLoading).toBe(false);
      expect(state.nodes).toEqual([{ id: 2 }]);
      expect(state.nodeToBeRemoved).toEqual(null);
    });
  });

  describe('RECEIVE_NODE_REMOVAL_ERROR', () => {
    beforeEach(() => {
      state.isLoading = true;
      state.nodeToBeRemoved = 1;
    });

    it('resets state', () => {
      mutations[types.RECEIVE_NODE_REMOVAL_ERROR](state);

      expect(state.isLoading).toBe(false);
      expect(state.nodeToBeRemoved).toEqual(null);
    });
  });

  describe('SET_STATUS_FILTER', () => {
    it('sets statusFilter', () => {
      mutations[types.SET_STATUS_FILTER](state, 'healthy');

      expect(state.statusFilter).toBe('healthy');
    });
  });

  describe('SET_SEARCH_FILTER', () => {
    it('sets searchFilter', () => {
      mutations[types.SET_SEARCH_FILTER](state, 'search');

      expect(state.searchFilter).toBe('search');
    });
  });
});
