import * as types from './mutation_types';

export default {
  [types.SET_SCAN_RESULT_POLICIES](state, policies) {
    state.scanResultPolicies = policies;
    state.scanResultPoliciesError = null;
  },
  [types.SCAN_RESULT_POLICIES_FAILED](state, error) {
    state.scanResultPolicies = [];
    state.scanResultPoliciesError = error;
  },
};
