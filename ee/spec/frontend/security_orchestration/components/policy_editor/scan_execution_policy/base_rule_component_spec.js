import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/base_rule_component.vue';
import {
  SCAN_EXECUTION_SCHEDULE_RULE,
  SCAN_EXECUTION_RULES_LABELS,
  SCAN_EXECUTION_PIPELINE_RULE,
  SCAN_EXECUTION_RULES_PIPELINE_KEY,
  SCAN_EXECUTION_RULES_SCHEDULE_KEY,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';

describe('BaseRuleComponent', () => {
  let wrapper;
  const ruleLabel = s__('ScanExecutionPolicy|if');
  const initRule = {
    type: SCAN_EXECUTION_SCHEDULE_RULE,
    branches: [],
  };

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(BaseRuleComponent, {
      propsData: {
        initRule,
        ruleLabel,
        ...options,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findDeleteButton = () => wrapper.findByTestId('remove-rule');
  const findRuleTypeDropDown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findRuleLabel = () => wrapper.findByTestId('rule-component-label');
  const findBranchesInputField = () => wrapper.findByTestId('rule-branches');
  const findBranchesLabel = () => wrapper.findByTestId('rule-branches-label');

  const selectBranches = async (branches) => {
    findBranchesInputField().vm.$emit('input', branches);
    await nextTick();
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render pipeline rule by default', () => {
      expect(findRuleLabel().text()).toEqual(ruleLabel);
      expect(findRuleTypeDropDown().props('selected')).toBe(SCAN_EXECUTION_RULES_PIPELINE_KEY);
    });

    it('should render pipeline rule component by default', () => {
      expect(findRuleLabel().text()).toEqual(ruleLabel);
      expect(findRuleTypeDropDown().props('selected')).toBe(SCAN_EXECUTION_RULES_PIPELINE_KEY);
      expect(findBranchesInputField().attributes('value')).toBe('');
    });

    it('should select pipeline rule', async () => {
      findRuleTypeDropDown().vm.$emit('select', SCAN_EXECUTION_RULES_SCHEDULE_KEY);
      await nextTick();
      const [eventPayload] = wrapper.emitted()['select-rule'];

      expect(eventPayload[0]).toEqual(SCAN_EXECUTION_RULES_LABELS.schedule.toLowerCase());
    });

    it('should select list of branches', async () => {
      const branches = 'main,branch1,branch2';

      await selectBranches(branches);
      const [eventPayload] = wrapper.emitted().changed;

      expect(eventPayload[0]).toEqual({
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        branches: branches.split(','),
      });
    });

    it.each`
      isBranchScope | expectedResult
      ${true}       | ${true}
      ${false}      | ${false}
    `('should render branches input', ({ isBranchScope, expectedResult }) => {
      createComponent({ isBranchScope });

      expect(findBranchesInputField().exists()).toBe(expectedResult);
    });

    it('should emit array of branches and correct type', async () => {
      await selectBranches('main, branch');

      expect(wrapper.emitted()).toEqual({
        changed: [[{ branches: ['main', 'branch'], type: SCAN_EXECUTION_SCHEDULE_RULE }]],
      });
    });

    it('should trim branch names from white spaces', async () => {
      await selectBranches('main , branch  ,    branch2    ');

      expect(wrapper.emitted()).toEqual({
        changed: [
          [{ branches: ['main', 'branch', 'branch2'], type: SCAN_EXECUTION_SCHEDULE_RULE }],
        ],
      });
    });

    it('should select correct rule', async () => {
      findRuleTypeDropDown().vm.$emit('select', SCAN_EXECUTION_RULES_PIPELINE_KEY);

      await nextTick();

      expect(wrapper.emitted()).toEqual({
        'select-rule': [[SCAN_EXECUTION_PIPELINE_RULE]],
      });
    });

    it('should remove rule', async () => {
      findDeleteButton().vm.$emit('click');

      await nextTick();

      expect(wrapper.emitted()).toEqual({
        remove: [[]],
      });
    });
  });

  describe('branches label', () => {
    it('displays "branches" if a branch has the wildcard operator', async () => {
      createComponent({
        initRule: {
          type: SCAN_EXECUTION_SCHEDULE_RULE,
          branches: ['releases/*'],
        },
      });
      await nextTick();
      expect(findBranchesLabel().text()).toBe('branches');
    });

    it('displays "branch" if a branch does not have the wildcard operator', async () => {
      createComponent({
        initRule: {
          type: SCAN_EXECUTION_SCHEDULE_RULE,
          branches: ['main'],
        },
      });
      await nextTick();
      expect(findBranchesLabel().text()).toBe('branch');
    });
  });
});
