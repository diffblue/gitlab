import { mountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder_v2.vue';
import SecurityScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/security_scan_rule_builder.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  emptyBuildRule,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';

describe('PolicyRuleBuilder V2', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const SECURITY_SCAN_RULE = {
    type: SCAN_FINDING,
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
    scanners: ['dast'],
    vulnerabilities_allowed: 1,
    severity_levels: ['high'],
    vulnerability_states: ['newly_detected'],
  };

  const factory = (propsData = {}, provide = {}) => {
    wrapper = mountExtended(PolicyRuleBuilder, {
      propsData: {
        initRule: emptyBuildRule(),
        ...propsData,
      },
      provide: {
        namespaceId: '1',
        namespaceType: NAMESPACE_TYPES.PROJECT,
        ...provide,
      },
    });
  };

  const findDeleteBtn = () => wrapper.findByTestId('remove-rule');
  const findSecurityScanRule = () => wrapper.findComponent(SecurityScanRuleBuilder);

  beforeEach(() => {
    jest
      .spyOn(Api, 'projectProtectedBranches')
      .mockReturnValue(Promise.resolve(PROTECTED_BRANCHES_MOCK));
  });

  describe('initial rendering', () => {
    beforeEach(() => {
      factory();
    });

    it('does not render the security scan rule', () => {
      expect(findSecurityScanRule().exists()).toBe(false);
    });

    it('renders the delete button', () => {
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('emits the remove event when removing the rule', async () => {
      await findDeleteBtn().vm.$emit('click');

      expect(wrapper.emitted().remove).toHaveLength(1);
    });
  });

  describe('when a rule type is selected', () => {
    it.each`
      ruleType           | rule                  | showSecurityRule
      ${'unselected'}    | ${emptyBuildRule()}   | ${false}
      ${'security scan'} | ${SECURITY_SCAN_RULE} | ${true}
    `('renders the $ruleType policy', ({ rule, showSecurityRule }) => {
      factory({ initRule: rule });
      expect(findSecurityScanRule().exists()).toBe(showSecurityRule);
    });
  });
});
