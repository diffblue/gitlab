import * as types from './mutation_types';

export default {
  [types.LOADING_BRANCHES](state) {
    state.invalidBranches = [];
  },
  [types.INVALID_BRANCHES](state, invalidBranch) {
    state.invalidBranches.push(invalidBranch);
  },
};
