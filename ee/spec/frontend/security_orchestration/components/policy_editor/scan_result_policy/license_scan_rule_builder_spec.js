import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchExceptionSelector from 'ee/security_orchestration/components/branch_exception_selector.vue';
import LicenseScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/license_scan_rule_builder.vue';
import PolicyRuleBranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_branch_selection.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import StatusFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/status_filter.vue';
import LicenseFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/license_filter.vue';
import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/scan_type_select.vue';
import {
  getDefaultRule,
  licenseScanBuildRule,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('LicenseScanRuleBuilder', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const UPDATED_RULE = {
    ...licenseScanBuildRule(),
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
    match_on_inclusion: false,
    license_types: ['MIT', 'BSD'],
    license_states: ['newly_detected', 'detected'],
  };

  const factory = ({ stubs = {}, props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(LicenseScanRuleBuilder, {
      propsData: {
        initRule: licenseScanBuildRule(),
        ...props,
      },
      provide: {
        namespaceType: NAMESPACE_TYPES.GROUP,
        glFeatures: {
          securityPoliciesBranchExceptions: true,
        },
        ...provide,
      },
      stubs: {
        BaseLayoutComponent,
        GlSprintf,
        PolicyRuleBranchSelection: true,
        StatusFilter,
        ...stubs,
      },
    });
  };

  const findBranches = () => wrapper.findComponent(PolicyRuleBranchSelection);
  const findGroupLevelBranches = () => wrapper.findByTestId('group-level-branch');
  const findPolicyRuleMultiSelect = () => wrapper.findComponent(PolicyRuleMultiSelect);
  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findLicenseFilter = () => wrapper.findComponent(LicenseFilter);
  const findScanTypeSelect = () => wrapper.findComponent(ScanTypeSelect);
  const findBranchExceptionSelector = () => wrapper.findComponent(BranchExceptionSelector);

  describe('initial rendering', () => {
    beforeEach(() => {
      factory();
    });

    it('renders one field for each attribute of the rule', () => {
      expect(findBranches().exists()).toBe(true);
      expect(findGroupLevelBranches().exists()).toBe(false);
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('includes select all option to all PolicyRuleMultiSelect', () => {
      expect(findPolicyRuleMultiSelect().props()).toEqual(
        expect.objectContaining({ includeSelectAll: true }),
      );
    });

    it('can change scan type', () => {
      factory();
      findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

      expect(wrapper.emitted('set-scan-type')).toEqual([[getDefaultRule(SCAN_FINDING)]]);
    });
  });

  describe('adding branch exceptions', () => {
    const exceptions = { branch_exceptions: ['main', 'test'] };

    it.each`
      namespaceType              | expectedResult
      ${NAMESPACE_TYPES.PROJECT} | ${true}
      ${NAMESPACE_TYPES.GROUP}   | ${false}
    `('should select exceptions only on project level', ({ namespaceType, expectedResult }) => {
      factory({
        provide: {
          namespaceType,
        },
      });

      expect(findBranchExceptionSelector().exists()).toBe(expectedResult);
    });

    it('should select exceptions', () => {
      factory({
        provide: {
          namespaceType: NAMESPACE_TYPES.PROJECT,
        },
      });

      findBranchExceptionSelector().vm.$emit('select', exceptions);

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            ...licenseScanBuildRule(),
            ...exceptions,
          },
        ],
      ]);
    });

    it('should display saved exceptions', () => {
      factory({
        props: {
          initRule: {
            ...licenseScanBuildRule(),
            ...exceptions,
          },
        },
        provide: {
          namespaceType: NAMESPACE_TYPES.PROJECT,
        },
      });

      expect(findBranchExceptionSelector().props('selectedExceptions')).toEqual(
        exceptions.branch_exceptions,
      );
    });
  });

  describe('when editing any attribute of the rule', () => {
    it.each`
      attribute               | currentComponent             | newValue                                                   | expected                                                   | event
      ${'branches'}           | ${findBranches}              | ${{ branches: [PROTECTED_BRANCHES_MOCK[0].name] }}         | ${{ branches: UPDATED_RULE.branches }}                     | ${'changed'}
      ${'license status'}     | ${findPolicyRuleMultiSelect} | ${'Newly Detected'}                                        | ${{ license_states: 'Newly Detected' }}                    | ${'input'}
      ${'license match type'} | ${findLicenseFilter}         | ${{ match_on_inclusion: UPDATED_RULE.match_on_inclusion }} | ${{ match_on_inclusion: UPDATED_RULE.match_on_inclusion }} | ${'changed'}
      ${'license type'}       | ${findLicenseFilter}         | ${{ license_types: UPDATED_RULE.license_types }}           | ${{ license_types: UPDATED_RULE.license_types }}           | ${'changed'}
    `(
      'triggers a changed event by $currentComponent for $attribute with the updated rule',
      async ({ currentComponent, newValue, expected, event }) => {
        factory();
        await currentComponent().vm.$emit(event, newValue);
        expect(wrapper.emitted().changed).toEqual([[expect.objectContaining(expected)]]);
      },
    );
  });

  describe('disabled feature flag', () => {
    it('should not render branch exceptions when feature flag is disabled', () => {
      factory({
        provide: {
          glFeatures: {
            securityPoliciesBranchExceptions: false,
          },
        },
      });

      expect(findBranchExceptionSelector().exists()).toBe(false);
    });
  });
});
