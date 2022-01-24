import * as types from './mutation_types';

export default {
  [types.REQUEST_NODES](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_NODES_SUCCESS](state, data) {
    state.isLoading = false;
    state.nodes = data;
  },
  [types.RECEIVE_NODES_ERROR](state) {
    state.isLoading = false;
    state.nodes = [];
  },
  [types.STAGE_NODE_REMOVAL](state, id) {
    state.nodeToBeRemoved = id;
  },
  [types.UNSTAGE_NODE_REMOVAL](state) {
    state.nodeToBeRemoved = null;
  },
  [types.REQUEST_NODE_REMOVAL](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_NODE_REMOVAL_SUCCESS](state) {
    state.isLoading = false;

    const index = state.nodes.findIndex((n) => n.id === state.nodeToBeRemoved);
    state.nodes.splice(index, 1);

    state.nodeToBeRemoved = null;
  },
  [types.RECEIVE_NODE_REMOVAL_ERROR](state) {
    state.isLoading = false;
    state.nodeToBeRemoved = null;
  },
  [types.SET_STATUS_FILTER](state, status) {
    state.statusFilter = status;
  },
};
