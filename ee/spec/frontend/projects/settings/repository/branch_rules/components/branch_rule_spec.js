import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchRule, {
  i18n,
} from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';
import { sprintf, n__ } from '~/locale';
import { branchRuleProvideMock, branchRulePropsMock } from '../mock_data';

describe('Branch rule', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(BranchRule, {
      provide: { ...branchRuleProvideMock, ...provide },
      propsData: { ...branchRulePropsMock, ...props },
    });
  };

  const findProtectionDetailsListItems = () => wrapper.findAllByRole('listitem');
  const findCodeOwners = () => wrapper.findByText(i18n.codeOwnerApprovalRequired);
  const findStatusChecks = (total) =>
    wrapper.findByText(
      sprintf(i18n.statusChecks, { total, subject: n__('check', 'checks', total) }),
    );
  const findApprovalRules = (total) =>
    wrapper.findByText(
      sprintf(i18n.approvalRules, { total, subject: n__('rule', 'rules', total) }),
    );

  beforeEach(() => createComponent());

  it.each`
    showCodeOwners | showStatusChecks | showApprovers
    ${true}        | ${true}          | ${true}
    ${false}       | ${false}         | ${false}
  `(
    'conditionally renders code owners, status checks, and approval rules',
    ({ showCodeOwners, showStatusChecks, showApprovers }) => {
      createComponent({ provide: { showCodeOwners, showStatusChecks, showApprovers } });
      const { statusChecksTotal, approvalRulesTotal } = branchRulePropsMock;

      expect(findCodeOwners().exists()).toBe(showCodeOwners);
      expect(findStatusChecks(statusChecksTotal).exists()).toBe(showStatusChecks);
      expect(findApprovalRules(approvalRulesTotal).exists()).toBe(showApprovers);
    },
  );

  it('renders the protection details list items', () => {
    expect(findProtectionDetailsListItems()).toHaveLength(wrapper.vm.approvalDetails.length);
    expect(findProtectionDetailsListItems().at(0).text()).toBe(i18n.allowForcePush);
    expect(findProtectionDetailsListItems().at(1).text()).toBe(wrapper.vm.pushAccessLevelsText);
  });

  it('renders branches count for wildcards', () => {
    createComponent({ props: { name: 'test-*' } });
    expect(findProtectionDetailsListItems().at(0).text()).toMatchInterpolatedText(
      sprintf(i18n.matchingBranches, {
        total: branchRulePropsMock.matchingBranchesCount,
        subject: n__('branch', 'branches', branchRulePropsMock.matchingBranchesCount),
      }),
    );
  });
});
