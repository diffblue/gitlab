import { HEADER_TOTAL_ENTRIES, HEADER_PAGE_NUMBER, HEADER_ITEMS_PER_PAGE } from '../constants';
import * as types from './mutation_types';

export default {
  [types.REQUEST_PENDING_MEMBERS](state) {
    state.isLoading = true;
    state.hasError = false;
  },

  [types.RECEIVE_PENDING_MEMBERS_SUCCESS](state, payload) {
    const { data, headers } = payload;
    state.members = data;

    state.total = Number(headers[HEADER_TOTAL_ENTRIES]);
    state.page = Number(headers[HEADER_PAGE_NUMBER]);
    state.perPage = Number(headers[HEADER_ITEMS_PER_PAGE]);

    state.isLoading = false;
  },

  [types.RECEIVE_PENDING_MEMBERS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },

  [types.SET_CURRENT_PAGE](state, pageNumber) {
    state.page = pageNumber;
  },
};
