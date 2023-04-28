import CEMutations from '~/diffs/store/mutations';

import * as types from './mutation_types';

export default {
  ...CEMutations,

  [types.SET_CODEQUALITY_ENDPOINT](state, endpoint) {
    Object.assign(state, { endpointCodequality: endpoint });
  },

  [types.SET_CODEQUALITY_DATA](state, codequalityDiffData) {
    Object.assign(state, { codequalityDiff: codequalityDiffData });
  },

  [types.SET_GENERATE_TEST_FILE_PATH](state, path) {
    state.generateTestFilePath = path;
  },
};
