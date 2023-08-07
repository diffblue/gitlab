import { convertToTitleCase } from '~/lib/utils/text_utility';
import DetailsDrawer from 'ee/security_orchestration/components/policy_drawer/scan_result/details_drawer.vue';
import PolicyDrawerLayout from 'ee/security_orchestration/components/policy_drawer/drawer_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import PolicyApprovals from 'ee/security_orchestration/components/policy_drawer/scan_result/policy_approvals.vue';
import {
  mockProjectWithAllApproverTypesScanResultPolicy,
  mockDefaultBranchesScanResultObject,
} from '../../../mocks/mock_scan_result_policy_data';

describe('DetailsDrawer component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');
  const findPolicyApprovals = () => wrapper.findComponent(PolicyApprovals);
  const findPolicyDrawerLayout = () => wrapper.findComponent(PolicyDrawerLayout);

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(DetailsDrawer, {
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

    it.each`
      prop             | expected
      ${'policy'}      | ${mockProjectWithAllApproverTypesScanResultPolicy}
      ${'description'} | ${mockDefaultBranchesScanResultObject.description}
    `('passes the correct $prop prop to the PolicyDrawerLayout component', ({ prop, expected }) => {
      expect(findPolicyDrawerLayout().props(prop)).toBe(expected);
    });

    it('renders the policy summary', () => {
      expect(findSummary().exists()).toBe(true);
    });

    it('renders the "RequireApproval" component correctly', () => {
      expect(findPolicyApprovals().exists()).toBe(true);
      expect(findPolicyApprovals().props('approvers')).toStrictEqual([
        ...mockProjectWithAllApproverTypesScanResultPolicy.groupApprovers,
        ...mockProjectWithAllApproverTypesScanResultPolicy.roleApprovers.map((r) =>
          convertToTitleCase(r.toLowerCase()),
        ),
        ...mockProjectWithAllApproverTypesScanResultPolicy.userApprovers,
      ]);
    });
  });
});
