import Vue from 'vue';
import {
  HEADER_TOTAL_ENTRIES,
  HEADER_PAGE_NUMBER,
  HEADER_ITEMS_PER_PAGE,
} from 'ee/billings/constants';
import * as types from './mutation_types';

export default {
  [types.REQUEST_BILLABLE_MEMBERS](state) {
    state.isLoading = true;
    state.hasError = false;
  },

  [types.RECEIVE_BILLABLE_MEMBERS_SUCCESS](state, payload) {
    const { data, headers } = payload;
    state.members = data;

    state.total = Number(headers[HEADER_TOTAL_ENTRIES]);
    state.page = Number(headers[HEADER_PAGE_NUMBER]);
    state.perPage = Number(headers[HEADER_ITEMS_PER_PAGE]);

    state.isLoading = false;
  },

  [types.RECEIVE_BILLABLE_MEMBERS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },

  [types.SET_SEARCH_QUERY](state, searchString) {
    state.search = searchString ?? null;
  },

  [types.SET_CURRENT_PAGE](state, pageNumber) {
    state.page = pageNumber;
  },

  [types.SET_SORT_OPTION](state, sortOption) {
    state.sort = sortOption;
  },

  [types.RESET_BILLABLE_MEMBERS](state) {
    state.members = [];

    state.total = null;
    state.page = null;
    state.perPage = null;

    state.isLoading = false;
  },

  [types.SET_BILLABLE_MEMBER_TO_REMOVE](state, memberToRemove) {
    if (!memberToRemove) {
      state.billableMemberToRemove = null;
    } else {
      state.billableMemberToRemove = state.members.find(
        (member) => member.id === memberToRemove.id,
      );
    }
  },

  [types.REMOVE_BILLABLE_MEMBER](state) {
    state.isLoading = true;
    state.hasError = false;
  },

  [types.REMOVE_BILLABLE_MEMBER_SUCCESS](state) {
    state.isLoading = false;
    state.hasError = false;
    state.billableMemberToRemove = null;
  },

  [types.REMOVE_BILLABLE_MEMBER_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
    state.billableMemberToRemove = null;
  },

  [types.FETCH_BILLABLE_MEMBER_DETAILS](state, { memberId }) {
    Vue.set(state.userDetails, memberId, {
      isLoading: true,
      items: [],
    });
  },

  [types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS](state, { memberId, memberships }) {
    Vue.set(state.userDetails, memberId, {
      isLoading: false,
      items: memberships,
    });
  },

  [types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR](state, { memberId }) {
    Vue.set(state.userDetails, memberId, {
      isLoading: false,
      items: [],
    });
  },
};
