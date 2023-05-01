import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import DefaultRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/default_rule_builder.vue';
import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder.vue';
import SecurityScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/security_scan_rule_builder.vue';
import LicenseScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/license_scan_rule_builder.vue';

import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  emptyBuildRule,
  SCAN_FINDING,
  securityScanBuildRule,
  licenseScanBuildRule,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';

describe('PolicyRuleBuilder', () => {
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
    license_states: ['newly_detected', 'detected'],
  };

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(PolicyRuleBuilder, {
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
      stubs: {
        DefaultRuleBuilder,
        BaseLayoutComponent,
      },
    });
  };

  const findDeleteBtn = () => wrapper.findByTestId('remove-rule');
  const findEmptyScanRuleBuilder = () => wrapper.findComponent(DefaultRuleBuilder);
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
      expect(findEmptyScanRuleBuilder().exists()).toBe(true);
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
      factory({ propsData: { initRule: rule } });
      expect(findSecurityScanRule().exists()).toBe(showSecurityRule);
      expect(findLicenseScanRule().exists()).toBe(showLicenseRule);
    });
  });

  describe('selects correct rule', () => {
    it.each`
      initialRule                | findComponent           | expectedRule
      ${licenseScanBuildRule()}  | ${findLicenseScanRule}  | ${securityScanBuildRule()}
      ${securityScanBuildRule()} | ${findSecurityScanRule} | ${licenseScanBuildRule()}
    `('selects correct rule for scan type', ({ initialRule, findComponent, expectedRule }) => {
      factory({
        propsData: {
          initRule: initialRule,
        },
      });

      findComponent().vm.$emit('changed', expectedRule);

      expect(wrapper.emitted('changed')).toEqual([[expectedRule]]);
    });
  });

  describe('preserve state', () => {
    it('should preserve state after editing and switching scan type', () => {
      factory({
        propsData: { initRule: licenseScanBuildRule() },
      });

      expect(findLicenseScanRule().props('initRule')).toEqual(licenseScanBuildRule());

      const updatedLicenceRule = {
        ...licenseScanBuildRule(),
        branches: ['main'],
      };

      findLicenseScanRule().vm.$emit('changed', updatedLicenceRule);

      findLicenseScanRule().vm.$emit('set-scan-type', securityScanBuildRule());

      expect(wrapper.emitted('changed')[0]).toEqual([updatedLicenceRule]);
      expect(wrapper.emitted('changed')[1]).toEqual([securityScanBuildRule()]);
    });
  });
});
