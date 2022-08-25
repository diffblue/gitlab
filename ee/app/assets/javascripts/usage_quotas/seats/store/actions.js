import * as GroupsApi from 'ee/api/groups_api';
import Api from 'ee/api';
import { createAlert, VARIANT_SUCCESS } from '~/flash';
import { s__, __ } from '~/locale';
import { MEMBER_ACTIVE_STATE, MEMBER_AWAITING_STATE } from '../constants';
import * as types from './mutation_types';

export const fetchBillableMembersList = ({ commit, dispatch, state }) => {
  commit(types.REQUEST_BILLABLE_MEMBERS);

  const { page, search, sort, hasLimitedFreePlan, previewFreeUserCap } = state;

  return GroupsApi.fetchBillableGroupMembersList(state.namespaceId, {
    page,
    search,
    sort,
    include_awaiting_members: hasLimitedFreePlan || previewFreeUserCap,
  })
    .then(({ data, headers }) => dispatch('receiveBillableMembersListSuccess', { data, headers }))
    .catch(() => dispatch('receiveBillableMembersListError'));
};

export const fetchGitlabSubscription = ({ commit, dispatch, state }) => {
  commit(types.REQUEST_GITLAB_SUBSCRIPTION);

  return Api.userSubscription(state.namespaceId)
    .then(({ data }) => dispatch('receiveGitlabSubscriptionSuccess', data))
    .catch(() => dispatch('receiveGitlabSubscriptionError'));
};

export const receiveBillableMembersListSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_BILLABLE_MEMBERS_SUCCESS, response);

export const receiveBillableMembersListError = ({ commit }) => {
  createAlert({
    message: s__('Billing|An error occurred while loading billable members list.'),
  });
  commit(types.RECEIVE_BILLABLE_MEMBERS_ERROR);
};

export const receiveGitlabSubscriptionSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS, response);

export const receiveGitlabSubscriptionError = ({ commit }) => {
  createAlert({
    message: s__('Billing|An error occurred while loading GitLab subscription details.'),
  });
  commit(types.RECEIVE_GITLAB_SUBSCRIPTION_ERROR);
};

export const setBillableMemberToRemove = ({ commit }, member) => {
  commit(types.SET_BILLABLE_MEMBER_TO_REMOVE, member);
};

export const changeMembershipState = async ({ commit, dispatch, state }, user) => {
  commit(types.CHANGE_MEMBERSHIP_STATE);

  try {
    const newState =
      user.membership_state === MEMBER_ACTIVE_STATE ? MEMBER_AWAITING_STATE : MEMBER_ACTIVE_STATE;

    await GroupsApi.changeMembershipState(state.namespaceId, user.id, newState);
    dispatch('changeMembershipStateSuccess');
  } catch {
    dispatch('changeMembershipStateError');
  }
};

export const changeMembershipStateSuccess = ({ commit, dispatch }) => {
  dispatch('fetchBillableMembersList');
  dispatch('fetchGitlabSubscription');

  commit(types.CHANGE_MEMBERSHIP_STATE_SUCCESS);
};

export const changeMembershipStateError = ({ commit }) => {
  createAlert({
    message: __('Something went wrong. Please try again.'),
  });

  commit(types.CHANGE_MEMBERSHIP_STATE_ERROR);
};

export const removeBillableMember = ({ dispatch, state, commit }) => {
  commit(types.REMOVE_BILLABLE_MEMBER);

  return GroupsApi.removeBillableMemberFromGroup(state.namespaceId, state.billableMemberToRemove.id)
    .then(() => dispatch('removeBillableMemberSuccess'))
    .catch(() => dispatch('removeBillableMemberError'));
};

export const removeBillableMemberSuccess = ({ dispatch, commit }) => {
  dispatch('fetchBillableMembersList');
  dispatch('fetchGitlabSubscription');

  createAlert({
    message: s__('Billing|User was successfully removed'),
    variant: VARIANT_SUCCESS,
  });

  commit(types.REMOVE_BILLABLE_MEMBER_SUCCESS);
};

export const removeBillableMemberError = ({ commit }) => {
  createAlert({
    message: s__('Billing|An error occurred while removing a billable member.'),
  });
  commit(types.REMOVE_BILLABLE_MEMBER_ERROR);
};

export const fetchBillableMemberDetails = ({ dispatch, commit, state }, memberId) => {
  if (state.userDetails[memberId]) {
    commit(types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS, {
      memberId,
      memberships: state.userDetails[memberId].items,
    });

    return Promise.resolve();
  }

  commit(types.FETCH_BILLABLE_MEMBER_DETAILS, { memberId });

  return GroupsApi.fetchBillableGroupMemberMemberships(state.namespaceId, memberId)
    .then(({ data }) =>
      commit(types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS, { memberId, memberships: data }),
    )
    .catch(() => dispatch('fetchBillableMemberDetailsError', memberId));
};

export const fetchBillableMemberDetailsError = ({ commit }, memberId) => {
  commit(types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR, { memberId });

  createAlert({
    message: s__('Billing|An error occurred while getting a billable member details.'),
  });
};

export const setSearchQuery = ({ commit, dispatch }, searchQuery) => {
  commit(types.SET_SEARCH_QUERY, searchQuery);

  dispatch('fetchBillableMembersList');
};

export const setCurrentPage = ({ commit, dispatch }, page) => {
  commit(types.SET_CURRENT_PAGE, page);

  dispatch('fetchBillableMembersList');
};

export const setSortOption = ({ commit, dispatch }, sortOption) => {
  commit(types.SET_SORT_OPTION, sortOption);

  dispatch('fetchBillableMembersList');
};
