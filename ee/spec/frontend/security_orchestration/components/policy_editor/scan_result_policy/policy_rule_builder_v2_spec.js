import { mountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder_v2.vue';
import SecurityScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/security_scan_rule_builder.vue';
import LicenseScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/license_scan_rule_builder.vue';

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

  const LICENSE_SCANNING_RULE = {
    type: 'license_finding',
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
    match_on_inclusion: true,
    license_types: [],
    license_states: ['newly_detected', 'pre_existing'],
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
        softwareLicenses: '[]',
        ...provide,
      },
    });
  };

  const findDeleteBtn = () => wrapper.findByTestId('remove-rule');
  const findSecurityScanRule = () => wrapper.findComponent(SecurityScanRuleBuilder);
  const findLicenseScanRule = () => wrapper.findComponent(LicenseScanRuleBuilder);

  beforeEach(() => {
    jest
      .spyOn(Api, 'projectProtectedBranches')
      .mockReturnValue(Promise.resolve(PROTECTED_BRANCHES_MOCK));
  });

  describe('initial rendering', () => {
    beforeEach(() => {
      factory();
    });

    it('does not render the license scan or security scan rule', () => {
      expect(findLicenseScanRule().exists()).toBe(false);
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
      ruleType           | rule                     | showSecurityRule | showLicenseRule
      ${'unselected'}    | ${emptyBuildRule()}      | ${false}         | ${false}
      ${'security scan'} | ${SECURITY_SCAN_RULE}    | ${true}          | ${false}
      ${'license scan'}  | ${LICENSE_SCANNING_RULE} | ${false}         | ${true}
    `('renders the $ruleType policy', ({ rule, showSecurityRule, showLicenseRule }) => {
      factory({ initRule: rule });
      expect(findSecurityScanRule().exists()).toBe(showSecurityRule);
      expect(findLicenseScanRule().exists()).toBe(showLicenseRule);
    });
  });
});
