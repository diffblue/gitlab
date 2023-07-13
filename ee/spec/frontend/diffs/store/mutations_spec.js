import * as types from 'ee/diffs/store/mutation_types';
import mutations from 'ee/diffs/store/mutations';

describe('EE DiffsStoreMutations', () => {
  describe('SET_CODEQUALITY_ENDPOINT', () => {
    it('sets the endpoint into state', () => {
      const state = {};
      const endpoint = '/codequality_mr_diff.json';

      mutations[types.SET_CODEQUALITY_ENDPOINT](state, endpoint);

      expect(state.endpointCodequality).toEqual(endpoint);
    });
  });

  describe('SET_SAST_ENDPOINT', () => {
    it('sets the endpoint into state', () => {
      const state = {};
      const endpoint = '/sast_mr_diff.json';

      mutations[types.SET_SAST_ENDPOINT](state, endpoint);

      expect(state.endpointSast).toEqual(endpoint);
    });
  });

  describe('SET_CODEQUALITY_DATA', () => {
    it('should set codequality data', () => {
      const state = { codequalityDiff: {} };
      const codequality = {
        files: { 'app.js': [{ line: 1, description: 'Unexpected alert.', severity: 'minor' }] },
      };

      mutations[types.SET_CODEQUALITY_DATA](state, codequality);

      expect(state.codequalityDiff).toEqual(codequality);
    });
  });

  describe('SET_SAST_DATA', () => {
    it('should set sast data', () => {
      const state = { sastDiff: {} };
      const sast = {
        files: { 'app.js': [{ line: 1, description: 'Unexpected alert.', severity: 'minor' }] },
      };

      mutations[types.SET_SAST_DATA](state, sast);

      expect(state.sastDiff).toEqual(sast);
    });
  });
});
