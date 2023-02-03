import Vue from 'vue';
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
  [types.REQUEST_MEMBERS](state) {
    state.loading = true;
  },
  [types.RECEIVE_MEMBERS_FINISH](state) {
    state.loading = false;
  },
  [types.RECEIVE_MEMBERS_ERROR](state) {
    state.loading = false;
  },
  [types.RECEIVE_MEMBER_SUCCESS](state, { rule, users }) {
    Vue.set(state.usersForRules, rule.id, users);
  },
};
