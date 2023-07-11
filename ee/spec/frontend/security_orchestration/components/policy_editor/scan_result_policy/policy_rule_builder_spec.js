import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DefaultRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/default_rule_builder.vue';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder.vue';
import SecurityScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/security_scan_rule_builder.vue';
import LicenseScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/license_scan_rule_builder.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  SCAN_FINDING,
  LICENSE_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import {
  emptyBuildRule,
  securityScanBuildRule,
  licenseScanBuildRule,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';

describe('PolicyRuleBuilder', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const SECURITY_SCAN_RULE = {
    ...securityScanBuildRule(),
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
    scanners: ['dast'],
    severity_levels: ['high'],
    vulnerability_states: ['newly_detected'],
  };

  const LICENSE_SCANNING_RULE = {
    ...licenseScanBuildRule(),
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
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
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyScanRuleBuilder = () => wrapper.findComponent(DefaultRuleBuilder);
  const findSecurityScanRule = () => wrapper.findComponent(SecurityScanRuleBuilder);
  const findLicenseScanRule = () => wrapper.findComponent(LicenseScanRuleBuilder);

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

  describe('removing a rule', () => {
    it.each`
      ruleType           | rule                     | findComponent
      ${'unselected'}    | ${emptyBuildRule()}      | ${findEmptyScanRuleBuilder}
      ${'security scan'} | ${SECURITY_SCAN_RULE}    | ${findSecurityScanRule}
      ${'license scan'}  | ${LICENSE_SCANNING_RULE} | ${findLicenseScanRule}
    `(
      'emits the remove event when removing the $ruleType rule',
      async ({ findComponent, rule }) => {
        factory({ propsData: { initRule: rule } });
        await findComponent().vm.$emit('remove');
        expect(wrapper.emitted().remove).toHaveLength(1);
      },
    );
  });

  describe('error handling', () => {
    it.each`
      findComponent               | rule
      ${findEmptyScanRuleBuilder} | ${''}
      ${findSecurityScanRule}     | ${SCAN_FINDING}
      ${findLicenseScanRule}      | ${LICENSE_FINDING}
    `('should display correct error message', async ({ findComponent, rule }) => {
      factory({
        propsData: {
          initRule: { type: rule },
        },
      });

      const error = 'test error message';

      expect(findAlert().exists()).toBe(false);

      await findComponent().vm.$emit('error', error);

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(error);
    });
  });
});
