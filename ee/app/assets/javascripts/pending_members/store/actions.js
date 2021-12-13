import * as GroupsApi from 'ee/api/groups_api';
import createFlash from '~/flash';
import { PENDING_MEMBERS_LIST_ERROR } from 'ee/pending_members/constants';
import * as types from './mutation_types';

export const fetchPendingMembersList = ({ commit, state }) => {
  commit(types.REQUEST_PENDING_MEMBERS);

  const { page, search } = state;

  return GroupsApi.fetchPendingGroupMembersList(state.namespaceId, { page, search })
    .then(({ data, headers }) => commit(types.RECEIVE_PENDING_MEMBERS_SUCCESS, { data, headers }))
    .catch(() => {
      commit(types.RECEIVE_PENDING_MEMBERS_ERROR);
      createFlash({
        message: PENDING_MEMBERS_LIST_ERROR,
      });
    });
};

export const setCurrentPage = ({ commit, dispatch }, page) => {
  commit(types.SET_CURRENT_PAGE, page);

  dispatch('fetchPendingMembersList');
};
