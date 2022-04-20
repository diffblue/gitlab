import * as types from 'ee/approvals/stores/modules/security_orchestration/mutation_types';
import mutations from 'ee/approvals/stores/modules/security_orchestration/mutations';
import createState from 'ee/approvals/stores/modules/security_orchestration/state';

describe('security orchestration mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.SET_SCAN_RESULT_POLICIES, () => {
    it('sets scan result policies with no error', () => {
      const policies = [{ name: 'policyName' }];
      mutations[types.SET_SCAN_RESULT_POLICIES](state, policies);

      expect(state.scanResultPolicies).toBe(policies);
      expect(state.scanResultPoliciesError).toBeNull();
    });
  });

  describe(types.SCAN_RESULT_POLICIES_FAILED, () => {
    it('reset scan result policies with errors', () => {
      const error = 'error';
      mutations[types.SCAN_RESULT_POLICIES_FAILED](state, error);

      expect(state.scanResultPolicies).toEqual([]);
      expect(state.scanResultPoliciesError).toBe(error);
    });
  });
});
