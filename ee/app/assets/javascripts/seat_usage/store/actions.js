import * as GroupsApi from 'ee/api/groups_api';
import createFlash, { FLASH_TYPES } from '~/flash';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const fetchBillableMembersList = ({ commit, dispatch, state }) => {
  commit(types.REQUEST_BILLABLE_MEMBERS);

  const { page, search, sort } = state;

  return GroupsApi.fetchBillableGroupMembersList(state.namespaceId, { page, search, sort })
    .then(({ data, headers }) => dispatch('receiveBillableMembersListSuccess', { data, headers }))
    .catch(() => dispatch('receiveBillableMembersListError'));
};

export const receiveBillableMembersListSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_BILLABLE_MEMBERS_SUCCESS, response);

export const receiveBillableMembersListError = ({ commit }) => {
  createFlash({
    message: s__('Billing|An error occurred while loading billable members list'),
  });
  commit(types.RECEIVE_BILLABLE_MEMBERS_ERROR);
};

export const resetBillableMembers = ({ commit }) => {
  commit(types.RESET_BILLABLE_MEMBERS);
};

export const setBillableMemberToRemove = ({ commit }, member) => {
  commit(types.SET_BILLABLE_MEMBER_TO_REMOVE, member);
};

export const removeBillableMember = ({ dispatch, state }) => {
  return GroupsApi.removeBillableMemberFromGroup(state.namespaceId, state.billableMemberToRemove.id)
    .then(() => dispatch('removeBillableMemberSuccess'))
    .catch(() => dispatch('removeBillableMemberError'));
};

export const removeBillableMemberSuccess = ({ dispatch, commit }) => {
  dispatch('fetchBillableMembersList');

  createFlash({
    message: s__('Billing|User was successfully removed'),
    type: FLASH_TYPES.SUCCESS,
  });

  commit(types.REMOVE_BILLABLE_MEMBER_SUCCESS);
};

export const removeBillableMemberError = ({ commit }) => {
  createFlash({
    message: s__('Billing|An error occurred while removing a billable member'),
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

  commit(types.FETCH_BILLABLE_MEMBER_DETAILS, memberId);

  return GroupsApi.fetchBillableGroupMemberMemberships(state.namespaceId, memberId)
    .then(({ data }) =>
      commit(types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS, { memberId, memberships: data }),
    )
    .catch(() => dispatch('fetchBillableMemberDetailsError', memberId));
};

export const fetchBillableMemberDetailsError = ({ commit }, memberId) => {
  commit(types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR, memberId);

  createFlash({
    message: s__('Billing|An error occurred while getting a billable member details'),
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
