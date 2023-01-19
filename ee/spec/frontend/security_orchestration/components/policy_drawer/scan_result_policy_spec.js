import ScanResultPolicy from 'ee/security_orchestration/components/policy_drawer/scan_result_policy.vue';
import PolicyDrawerLayout from 'ee/security_orchestration/components/policy_drawer/policy_drawer_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import RequireApprovals from 'ee/security_orchestration/components/policy_drawer/require_approvals.vue';
import { mockProjectScanResultPolicy } from '../../mocks/mock_scan_result_policy_data';

describe('ScanResultPolicy component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');
  const findRequireApprovals = () => wrapper.findComponent(RequireApprovals);

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(ScanResultPolicy, {
      propsData,
      provide: { namespaceType: NAMESPACE_TYPES.PROJECT },
      stubs: {
        PolicyDrawerLayout,
      },
    });
  };

  describe('default policy', () => {
    beforeEach(() => {
      factory({ propsData: { policy: mockProjectScanResultPolicy } });
    });

    it('does render the policy summary', () => {
      expect(findRequireApprovals().exists()).toBe(true);
      expect(findSummary().exists()).toBe(true);
    });
  });
});
