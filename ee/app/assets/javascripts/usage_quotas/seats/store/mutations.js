import Vue from 'vue';
import {
  HEADER_TOTAL_ENTRIES,
  HEADER_PAGE_NUMBER,
  HEADER_ITEMS_PER_PAGE,
} from 'ee/usage_quotas/seats/constants';
import * as types from './mutation_types';

export default {
  // Gitlab subscription
  [types.REQUEST_GITLAB_SUBSCRIPTION](state) {
    state.isLoadingGitlabSubscription = true;
    state.hasError = false;
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

    state.isLoadingGitlabSubscription = false;
  },

  [types.RECEIVE_GITLAB_SUBSCRIPTION_ERROR](state) {
    state.isLoadingGitlabSubscription = false;
    state.hasError = true;
  },

  // Search & Sort
  [types.SET_SEARCH_QUERY](state, searchString) {
    state.search = searchString ?? null;
  },

  [types.SET_CURRENT_PAGE](state, pageNumber) {
    state.page = pageNumber;
  },

  [types.SET_SORT_OPTION](state, sortOption) {
    state.sort = sortOption;
  },

  // Billable member list
  [types.REQUEST_BILLABLE_MEMBERS](state) {
    state.isLoadingBillableMembers = true;
    state.hasError = false;
  },

  [types.RECEIVE_BILLABLE_MEMBERS_SUCCESS](state, payload) {
    const { data, headers } = payload;
    state.members = data;

    state.total = Number(headers[HEADER_TOTAL_ENTRIES]);
    state.page = Number(headers[HEADER_PAGE_NUMBER]);
    state.perPage = Number(headers[HEADER_ITEMS_PER_PAGE]);

    state.isLoadingBillableMembers = false;
  },

  [types.RECEIVE_BILLABLE_MEMBERS_ERROR](state) {
    state.isLoadingBillableMembers = false;
    state.hasError = true;
  },

  // Billable member removal
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
    state.isRemovingBillableMember = true;
    state.hasError = false;
  },

  [types.REMOVE_BILLABLE_MEMBER_SUCCESS](state) {
    state.isRemovingBillableMember = false;
    state.billableMemberToRemove = null;
  },

  [types.REMOVE_BILLABLE_MEMBER_ERROR](state) {
    state.isRemovingBillableMember = false;
    state.billableMemberToRemove = null;
  },

  // Billable member details
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
