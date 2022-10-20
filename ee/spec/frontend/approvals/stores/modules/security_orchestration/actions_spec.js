import * as actions from 'ee/approvals/stores/modules/security_orchestration/actions';
import testAction from 'helpers/vuex_action_helper';
import * as types from 'ee/approvals/stores/modules/security_orchestration/mutation_types';
import getInitialState from 'ee/approvals/stores/modules/security_orchestration/state';
import { gqClient } from 'ee/security_orchestration/utils';

describe('security orchestration actions', () => {
  describe('fetchScanResultPolicies', () => {
    it('sets SCAN_RESULT_POLICIES_FAILED when failing', () => {
      jest.spyOn(gqClient, 'query').mockResolvedValue(Promise.reject());

      return testAction(
        actions.fetchScanResultPolicies,
        'namespace/project',
        getInitialState(),
        [{ type: types.SCAN_RESULT_POLICIES_FAILED }],
        [],
      );
    });

    it('sets SCAN_RESULT_POLICIES_FAILED when succeeding', () => {
      const policies = [
        {
          name: 'policyName',
          yaml: 'name: policyName',
          userApprovers: [{ id: 1, name: 'username' }],
          groupApprovers: [],
          source: { project: { fullPath: 'path/policy' } },
        },
      ];
      const expectedPolicies = [
        {
          name: 'policyName',
          isSelected: false,
          approvers: [{ id: 1, name: 'username' }],
          source: { project: { fullPath: 'path/policy' } },
        },
      ];
      const queryResponse = { data: { namespace: { scanResultPolicies: { nodes: policies } } } };

      jest.spyOn(gqClient, 'query').mockResolvedValue(queryResponse);

      return testAction(
        actions.fetchScanResultPolicies,
        'namespace/project',
        getInitialState(),
        [{ type: types.SET_SCAN_RESULT_POLICIES, payload: expectedPolicies }],
        [],
      );
    });

    it('sets SCAN_RESULT_POLICIES_FAILED with empty payload if parsing failed', () => {
      const policies = [{ name: 'policyName', yaml: '' }];
      const expectedPolicies = [];
      const queryResponse = { data: { namespace: { scanResultPolicies: { nodes: policies } } } };

      jest.spyOn(gqClient, 'query').mockResolvedValue(queryResponse);

      return testAction(
        actions.fetchScanResultPolicies,
        'namespace/project',
        getInitialState(),
        [{ type: types.SET_SCAN_RESULT_POLICIES, payload: expectedPolicies }],
        [],
      );
    });
  });
});
