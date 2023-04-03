import { convertToTitleCase } from '~/lib/utils/text_utility';
import ScanResultPolicy from 'ee/security_orchestration/components/policy_drawer/scan_result_policy.vue';
import PolicyDrawerLayout from 'ee/security_orchestration/components/policy_drawer/policy_drawer_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import RequireApprovals from 'ee/security_orchestration/components/policy_drawer/require_approvals.vue';
import { mockProjectWithAllApproverTypesScanResultPolicy } from '../../mocks/mock_scan_result_policy_data';

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
      factory({ propsData: { policy: mockProjectWithAllApproverTypesScanResultPolicy } });
    });

    it('renders the policy summary', () => {
      expect(findSummary().exists()).toBe(true);
    });

    it('renders the "RequireApproval" component correctly', () => {
      expect(findRequireApprovals().exists()).toBe(true);
      expect(findRequireApprovals().props('approvers')).toStrictEqual([
        ...mockProjectWithAllApproverTypesScanResultPolicy.groupApprovers,
        ...mockProjectWithAllApproverTypesScanResultPolicy.roleApprovers.map((r) =>
          convertToTitleCase(r.toLowerCase()),
        ),
        ...mockProjectWithAllApproverTypesScanResultPolicy.userApprovers,
      ]);
    });
  });
});
