import mutations from 'ee/security_orchestration/store/modules/scan_result_policies/mutations';
import getInitialState from 'ee/security_orchestration/store/modules/scan_result_policies/state';
import * as types from 'ee/security_orchestration/store/modules/scan_result_policies/mutation_types';

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

  describe(types.INVALID_PROTECTED_BRANCHES, () => {
    it('appends new branches into invalidBranches', () => {
      const branchName = 'main';
      mutations[types.INVALID_PROTECTED_BRANCHES](state, branchName);
      expect(state.invalidBranches).toEqual([branchName]);
    });
  });
});
