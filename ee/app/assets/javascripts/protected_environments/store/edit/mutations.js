import * as types from './mutation_types';

export const mutations = {
  [types.REQUEST_PROTECTED_ENVIRONMENTS](state) {
    state.loading = true;
  },
  [types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS](state, environments) {
    state.loading = false;
    state.protectedEnvironments = environments;
  },
  [types.RECEIVE_PROTECTED_ENVIRONMENTS_ERROR](state) {
    state.loading = false;
  },
};
