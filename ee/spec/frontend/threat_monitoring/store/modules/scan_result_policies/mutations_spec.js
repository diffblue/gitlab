import * as types from 'ee/threat_monitoring/store/modules/scan_result_policies/mutation_types';
import mutations from 'ee/threat_monitoring/store/modules/scan_result_policies/mutations';
import getInitialState from 'ee/threat_monitoring/store/modules/scan_result_policies/state';

describe('ScanResultPolicies mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.LOADING_BRANCHES, () => {
    it('resets invalid branches', () => {
      mutations[types.LOADING_BRANCHES](state);
      expect(state.invalidBranches).toEqual([]);
    });
  });

  describe(types.INVALID_BRANCHES, () => {
    it('appends new branches into invalidBranches', () => {
      const branchName = 'main';
      mutations[types.INVALID_BRANCHES](state, branchName);
      expect(state.invalidBranches).toEqual([branchName]);
    });
  });
});
