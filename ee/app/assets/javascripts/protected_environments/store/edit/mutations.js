import Vue from 'vue';
import * as types from './mutation_types';

export const mutations = {
  [types.REQUEST_PROTECTED_ENVIRONMENTS](state) {
    state.loading = true;
  },
  [types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS](state, environments) {
    state.loading = false;
    state.protectedEnvironments = environments;
    state.newDeployAccessLevelsForEnvironment = Object.fromEntries(
      environments.map(({ name }) => [name, []]),
    );
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
  [types.RECEIVE_MEMBER_SUCCESS](state, { type, rule, users }) {
    Vue.set(state.usersForRules, `${type}-${rule.id}`, users);
  },
  [types.REQUEST_UPDATE_PROTECTED_ENVIRONMENT](state) {
    state.loading = true;
  },
  [types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_SUCCESS](state, environment) {
    const index = state.protectedEnvironments.findIndex((env) => env.name === environment.name);
    Vue.set(state.protectedEnvironments, index, environment);
    Vue.set(state.newDeployAccessLevelsForEnvironment, environment.name, []);

    state.loading = false;
  },
  [types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_ERROR](state) {
    state.loading = false;
  },
  [types.SET_RULE](state, { environment, rules }) {
    state.newDeployAccessLevelsForEnvironment[environment.name] = rules;
  },
  [types.EDIT_RULE](state, rule) {
    Vue.set(state.editingRules, rule.id, { ...rule });
  },
  [types.RECEIVE_RULE_UPDATED](state, rule) {
    Vue.set(state.editingRules, rule.id, null);
  },
  [types.DELETE_PROTECTED_ENVIRONMENT_SUCCESS](state, { name }) {
    state.protectedEnvironments = state.protectedEnvironments.filter((env) => env.name !== name);
    Vue.set(state.newDeployAccessLevelsForEnvironment, name, []);

    state.loading = false;
  },
};
