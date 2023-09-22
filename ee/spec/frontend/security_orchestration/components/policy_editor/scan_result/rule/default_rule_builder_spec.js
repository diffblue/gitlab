import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import BranchExceptionSelector from 'ee/security_orchestration/components/policy_editor/branch_exception_selector.vue';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import DefaultRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/default_rule_builder.vue';
import BranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result/rule/branch_selection.vue';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_type_select.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import {
  getDefaultRule,
  SCAN_FINDING,
  LICENSE_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { SCAN_RESULT_BRANCH_TYPE_OPTIONS } from 'ee/security_orchestration/components/policy_editor/constants';

describe('DefaultRuleBuilder', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMount(DefaultRuleBuilder, {
      propsData: {
        initRule: getDefaultRule(),
        ...props,
      },
      provide: {
        namespaceType: NAMESPACE_TYPES.GROUP,
        ...provide,
      },
      stubs: {
        SectionLayout,
        GlSprintf,
      },
    });
  };

  const findScanTypeSelect = () => wrapper.findComponent(ScanTypeSelect);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findBranchSelection = () => wrapper.findComponent(BranchSelection);
  const findBranchExceptionSelector = () => wrapper.findComponent(BranchExceptionSelector);

  beforeEach(() => {
    createComponent();
  });

  it('has unselected scan type and branches by default', () => {
    expect(findScanTypeSelect().props('scanType')).toBe('');
    expect(findScanFilterSelector().props('disabled')).toBe(true);
    expect(findBranchSelection().exists()).toBe(true);
  });

  it.each([NAMESPACE_TYPES.GROUP, NAMESPACE_TYPES.PROJECT])(
    'has specific default branch type list based on namespace type',
    (namespaceType) => {
      createComponent({
        provide: {
          namespaceType,
        },
      });

      expect(findBranchSelection().props('branchTypes')).toEqual(
        SCAN_RESULT_BRANCH_TYPE_OPTIONS(namespaceType),
      );
    },
  );

  it('selects type without branches', () => {
    findScanTypeSelect().vm.$emit('select', LICENSE_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([[getDefaultRule(LICENSE_FINDING)]]);
  });

  it('selects branches and scan type', () => {
    findBranchSelection().vm.$emit('changed', { branches: ['main'] });

    expect(wrapper.emitted('set-scan-type')).toBeUndefined();

    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([
      [
        {
          type: SCAN_FINDING,
          scanners: [],
          severity_levels: [],
          vulnerabilities_allowed: 0,
          vulnerability_states: [],
          branches: ['main'],
        },
      ],
    ]);
  });

  it('selects branch type and scan type', () => {
    findBranchSelection().vm.$emit('set-branch-type', 'protected');

    expect(wrapper.emitted('set-scan-type')).toBeUndefined();

    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([
      [
        {
          type: SCAN_FINDING,
          scanners: [],
          severity_levels: [],
          vulnerabilities_allowed: 0,
          vulnerability_states: [],
          branch_type: 'protected',
        },
      ],
    ]);
  });

  it('does not render branch exceptions selector on group level', () => {
    expect(findBranchExceptionSelector().exists()).toBe(false);
  });

  it('selects branch exceptions', () => {
    createComponent({
      provide: {
        glFeatures: {
          securityPoliciesBranchExceptions: true,
        },
        namespaceType: NAMESPACE_TYPES.PROJECT,
      },
    });

    findBranchExceptionSelector().vm.$emit('select', { branch_exceptions: ['main', 'test'] });

    expect(wrapper.emitted('set-scan-type')).toBeUndefined();

    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([
      [
        {
          type: SCAN_FINDING,
          scanners: [],
          vulnerabilities_allowed: 0,
          severity_levels: [],
          vulnerability_states: [],
          branch_type: 'protected',
          branch_exceptions: ['main', 'test'],
        },
      ],
    ]);
  });

  it('can remove branch exceptions', () => {
    createComponent({
      provide: {
        glFeatures: {
          securityPoliciesBranchExceptions: true,
        },
        namespaceType: NAMESPACE_TYPES.PROJECT,
      },
    });

    findBranchExceptionSelector().vm.$emit('select', { branch_exceptions: ['main', 'test'] });

    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([
      [
        {
          type: SCAN_FINDING,
          scanners: [],
          vulnerabilities_allowed: 0,
          severity_levels: [],
          vulnerability_states: [],
          branch_type: 'protected',
          branch_exceptions: ['main', 'test'],
        },
      ],
    ]);

    findBranchExceptionSelector().vm.$emit('remove');

    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')[1]).toEqual([
      {
        type: SCAN_FINDING,
        scanners: [],
        vulnerabilities_allowed: 0,
        severity_levels: [],
        vulnerability_states: [],
        branch_type: 'protected',
      },
    ]);
  });
});
