import Api from 'ee/api';
import * as types from './mutation_types';

export const fetchBranches = ({ commit, dispatch }, { branches, projectId }) => {
  const uniqBranches = branches.filter((value, index, self) => self.indexOf(value) === index);
  commit(types.LOADING_BRANCHES);
  uniqBranches.forEach((branch) => dispatch('fetchBranch', { branch, projectId }));
};

export const fetchBranch = ({ commit }, { branch, projectId }) => {
  return Api.projectProtectedBranch(projectId, branch).catch((error) => {
    const decomposedUrl = error.config.url.split('/');
    commit(types.INVALID_PROTECTED_BRANCHES, decomposedUrl[decomposedUrl.length - 1]);
  });
};
