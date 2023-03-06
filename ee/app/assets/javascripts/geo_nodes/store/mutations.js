import * as types from './mutation_types';

export default {
  [types.REQUEST_SITES](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_SITES_SUCCESS](state, data) {
    state.isLoading = false;
    state.sites = data;
  },
  [types.RECEIVE_SITES_ERROR](state) {
    state.isLoading = false;
    state.sites = [];
  },
  [types.STAGE_SITE_REMOVAL](state, id) {
    state.siteToBeRemoved = id;
  },
  [types.UNSTAGE_SITE_REMOVAL](state) {
    state.siteToBeRemoved = null;
  },
  [types.REQUEST_SITE_REMOVAL](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_SITE_REMOVAL_SUCCESS](state) {
    state.isLoading = false;

    const index = state.sites.findIndex((n) => n.id === state.siteToBeRemoved);
    state.sites.splice(index, 1);

    state.siteToBeRemoved = null;
  },
  [types.RECEIVE_SITE_REMOVAL_ERROR](state) {
    state.isLoading = false;
    state.siteToBeRemoved = null;
  },
  [types.SET_STATUS_FILTER](state, status) {
    state.statusFilter = status;
  },
  [types.SET_SEARCH_FILTER](state, search) {
    state.searchFilter = search;
  },
};
