import Vue from 'vue';
import {
  HEADER_TOTAL_ENTRIES,
  HEADER_PAGE_NUMBER,
  HEADER_ITEMS_PER_PAGE,
} from 'ee/usage_quotas/seats/constants';
import * as types from './mutation_types';

export default {
  [types.REQUEST_BILLABLE_MEMBERS](state) {
    state.isLoading = true;
    state.hasError = false;
  },

  [types.REQUEST_GITLAB_SUBSCRIPTION](state) {
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

  [types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS](state, payload) {
    const { usage, plan } = payload;

    state.seatsInSubscription = usage?.seats_in_subscription ?? 0;
    state.seatsInUse = usage?.seats_in_use ?? 0;
    state.maxSeatsUsed = usage?.max_seats_used ?? 0;
    state.seatsOwed = usage?.seats_owed ?? 0;
    state.activeTrial = Boolean(plan?.trial);

    if (state.hasLimitedFreePlan) {
      state.hasReachedFreePlanLimit = state.seatsInUse >= state.maxFreeNamespaceSeats;
    } else {
      state.hasReachedFreePlanLimit = false;
    }

    state.isLoading = false;
  },

  [types.RECEIVE_BILLABLE_MEMBERS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },

  [types.RECEIVE_GITLAB_SUBSCRIPTION_ERROR](state) {
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

  [types.CHANGE_MEMBERSHIP_STATE](state) {
    state.isLoading = true;
    state.hasError = false;
  },

  [types.CHANGE_MEMBERSHIP_STATE_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
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
