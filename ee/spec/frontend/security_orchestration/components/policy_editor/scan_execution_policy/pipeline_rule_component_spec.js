import { GlDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { s__ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/pipeline_rule_component.vue';
import {
  SCAN_EXECUTION_PIPELINE_RULE,
  SCAN_EXECUTION_RULES_LABELS,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';

describe('PipelineRuleComponent', () => {
  let wrapper;
  const ruleLabel = s__('ScanExecutionPolicy|if');
  const initRule = {
    type: SCAN_EXECUTION_PIPELINE_RULE,
    branches: [],
  };

  const createComponent = (options = {}) => {
    wrapper = mountExtended(PipelineRuleComponent, {
      propsData: {
        initRule,
        ruleLabel,
        ...options,
      },
    });
  };

  const findTypeDropDownItem = () => wrapper.findComponent(GlDropdownItem);
  const findPipelineRuleComponentLabel = () => wrapper.findByTestId('rule-component-label');
  const findRuleDropDown = () => wrapper.findByTestId('rule-component-type');
  const findBranchesInputField = () => wrapper.findByTestId('pipeline-rule-branches');
  const findDeleteButton = () => wrapper.findByTestId('remove-rule');

  it('should render pipeline rule component by default', () => {
    createComponent();

    expect(findPipelineRuleComponentLabel().text()).toEqual(ruleLabel);
    expect(findRuleDropDown().props('text')).toEqual(SCAN_EXECUTION_RULES_LABELS.pipeline);
    expect(findBranchesInputField().element.value).toEqual('');
  });

  describe('list of branches', () => {
    const selectBranches = async (branches) => {
      createComponent();
      findBranchesInputField().vm.$emit('input', branches);
      await nextTick();
    };

    it('should render comma separated list of branched', () => {
      const branches = ['main', 'test1', 'test2'];
      createComponent({
        initRule: {
          type: SCAN_EXECUTION_PIPELINE_RULE,
          branches,
        },
      });

      expect(findBranchesInputField().element.value).toEqual(branches.join(','));
    });

    it('should filter out empty spaces', () => {
      const branches = ['main', '  ', 'test2', undefined, null];

      createComponent({
        initRule: {
          type: SCAN_EXECUTION_PIPELINE_RULE,
          branches,
        },
      });

      expect(findBranchesInputField().element.value).toEqual('main,test2');
    });

    it('should emit array of branches and correct type', async () => {
      await selectBranches('main, branch');

      expect(wrapper.emitted()).toEqual({
        changed: [[{ branches: ['main', 'branch'], type: SCAN_EXECUTION_PIPELINE_RULE }]],
      });
    });

    it('should trim branch names from white spaces', async () => {
      await selectBranches('main , branch  ,    branch2    ');

      expect(wrapper.emitted()).toEqual({
        changed: [
          [{ branches: ['main', 'branch', 'branch2'], type: SCAN_EXECUTION_PIPELINE_RULE }],
        ],
      });
    });
  });

  describe('select rule type', () => {
    it('should select correct rule', async () => {
      createComponent();
      findTypeDropDownItem().vm.$emit('click');

      await nextTick();

      expect(wrapper.emitted()).toEqual({
        'select-rule': [[SCAN_EXECUTION_PIPELINE_RULE]],
      });
    });
  });

  describe('remove rule', () => {
    it('should remove rule', async () => {
      createComponent();
      findDeleteButton().vm.$emit('click');

      await nextTick();

      expect(wrapper.emitted()).toEqual({
        remove: [[]],
      });
    });
  });
});
