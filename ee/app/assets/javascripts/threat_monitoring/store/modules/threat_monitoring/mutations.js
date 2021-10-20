import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    state.environmentsEndpoint = endpoint;
  },
  [types.REQUEST_ENVIRONMENTS](state) {
    state.isLoadingEnvironments = true;
    state.errorLoadingEnvironments = false;
  },
  [types.RECEIVE_ENVIRONMENTS_SUCCESS](state, { environments, nextPage }) {
    state.environments = environments;
    state.nextPage = nextPage;
    state.isLoadingEnvironments = false;
    state.errorLoadingEnvironments = false;
    if (environments.length > 0 && state.currentEnvironmentId === -1)
      state.currentEnvironmentId = environments[0].id;
  },
  [types.RECEIVE_ENVIRONMENTS_ERROR](state) {
    state.isLoadingEnvironments = false;
    state.errorLoadingEnvironments = true;
  },
  [types.SET_CURRENT_ENVIRONMENT_ID](state, payload) {
    state.currentEnvironmentId = payload;
    state.allEnvironments = false;
  },
  [types.SET_ALL_ENVIRONMENTS](state) {
    state.allEnvironments = true;
  },
  [types.SET_CURRENT_TIME_WINDOW](state, payload) {
    state.currentTimeWindow = payload;
  },
  [types.SET_HAS_ENVIRONMENT](state, payload) {
    state.hasEnvironment = payload;
  },
};
