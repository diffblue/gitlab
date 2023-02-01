import Api from 'ee/api';
import * as types from './mutation_types';

export const fetchProtectedEnvironments = ({ state, commit }) => {
  commit(types.REQUEST_PROTECTED_ENVIRONMENTS);

  return Api.protectedEnvironments(state.projectId)
    .then(({ data }) => {
      commit(types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS, data);
    })
    .catch((error) => {
      commit(types.RECEIVE_PROTECTED_ENVIRONMENTS_ERROR, error);
    });
};
