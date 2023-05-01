import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import DefaultRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/default_rule_builder.vue';
import PolicyRuleBranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_branch_selection.vue';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/scan_type_select.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/scan_filter_selector.vue';
import {
  getDefaultRule,
  SCAN_FINDING,
  LICENSE_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';

describe('DefaultRuleBuilder', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(DefaultRuleBuilder, {
      propsData: {
        initRule: getDefaultRule(),
        ...props,
      },
      stubs: {
        BaseLayoutComponent,
        GlSprintf,
      },
    });
  };

  const findScanTypeSelect = () => wrapper.findComponent(ScanTypeSelect);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findPolicyRuleBranchSelection = () => wrapper.findComponent(PolicyRuleBranchSelection);

  beforeEach(() => {
    createComponent();
  });

  it('has unselected scan type and branches by default', () => {
    expect(findScanTypeSelect().props('scanType')).toBe('');
    expect(findScanFilterSelector().props('disabled')).toBe(true);
    expect(findPolicyRuleBranchSelection().exists()).toBe(true);
  });

  it('selects type without branches', () => {
    findScanTypeSelect().vm.$emit('select', LICENSE_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([[getDefaultRule(LICENSE_FINDING)]]);
  });

  it('selects branches and scan type', () => {
    findPolicyRuleBranchSelection().vm.$emit('changed', { branches: ['main'] });

    expect(wrapper.emitted('set-scan-type')).toBeUndefined();

    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([
      [
        {
          ...getDefaultRule(SCAN_FINDING),
          branches: ['main'],
        },
      ],
    ]);
  });
});
