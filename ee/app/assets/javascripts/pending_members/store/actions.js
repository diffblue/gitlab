import * as GroupsApi from 'ee/api/groups_api';
import {
  APPROVAL_ERROR_MESSAGE,
  APPROVAL_SUCCESSFUL_MESSAGE,
  PENDING_MEMBERS_LIST_ERROR,
} from '../constants';
import * as types from './mutation_types';

export const fetchPendingMembersList = ({ commit, state }) => {
  commit(types.REQUEST_PENDING_MEMBERS);

  const { page, search } = state;

  return GroupsApi.fetchPendingGroupMembersList(state.namespaceId, { page, search })
    .then(({ data, headers }) => commit(types.RECEIVE_PENDING_MEMBERS_SUCCESS, { data, headers }))
    .catch(() => {
      commit(types.RECEIVE_PENDING_MEMBERS_ERROR);
      commit(types.SHOW_ALERT, {
        alertMessage: PENDING_MEMBERS_LIST_ERROR,
        alertVariant: 'danger',
      });
    });
};

export const setCurrentPage = ({ commit, dispatch }, page) => {
  commit(types.SET_CURRENT_PAGE, page);

  dispatch('fetchPendingMembersList');
};

export const approveMember = ({ commit, state }, id) => {
  commit(types.SET_MEMBER_AS_LOADING, id);

  return GroupsApi.approvePendingGroupMember(state.namespaceId, id)
    .then(() => {
      commit(types.SET_MEMBER_AS_APPROVED, id);
      commit(types.SHOW_ALERT, {
        memberId: id,
        alertMessage: APPROVAL_SUCCESSFUL_MESSAGE,
        alertVariant: 'info',
      });
    })
    .catch(() => {
      commit(types.SET_MEMBER_ERROR, id);
      commit(types.SHOW_ALERT, {
        memberId: id,
        alertMessage: APPROVAL_ERROR_MESSAGE,
        alertVariant: 'danger',
      });
    });
};
export const dismissAlert = ({ commit }) => {
  commit(types.DISMISS_ALERT);
};
