import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/base_rule_component.vue';
import BranchTypeSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/branch_type_selector.vue';
import {
  SCAN_EXECUTION_SCHEDULE_RULE,
  SCAN_EXECUTION_PIPELINE_RULE,
  SCAN_EXECUTION_RULES_PIPELINE_KEY,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import {
  ALL_PROTECTED_BRANCHES,
  SPECIFIC_BRANCHES,
  VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS,
} from 'ee/security_orchestration/components/policy_editor/constants';

describe('BaseRuleComponent', () => {
  let wrapper;
  const initRule = {
    type: SCAN_EXECUTION_SCHEDULE_RULE,
    branches: [],
  };

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(BaseRuleComponent, {
      propsData: {
        initRule,
        ...options,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findDeleteButton = () => wrapper.findByTestId('remove-rule');
  const findRuleTypeDropDown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findBranchesLabel = () => wrapper.findByTestId('rule-branches-label');
  const findBranchTypeSelector = () => wrapper.findComponent(BranchTypeSelector);

  const selectBranches = async (branches) => {
    findBranchTypeSelector().vm.$emit('input', branches);
    await nextTick();
  };

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders pipeline rule by default', () => {
      expect(findRuleTypeDropDown().props('selected')).toBe(SCAN_EXECUTION_RULES_PIPELINE_KEY);
    });

    it('renders pipeline rule component by default', () => {
      expect(findRuleTypeDropDown().props('selected')).toBe(SCAN_EXECUTION_RULES_PIPELINE_KEY);
      expect(findBranchTypeSelector().props('branchesToAdd')).toBe('');
    });

    it('selects pipeline rule', async () => {
      findRuleTypeDropDown().vm.$emit('select', SCAN_EXECUTION_RULES_PIPELINE_KEY);
      await nextTick();
      const [eventPayload] = wrapper.emitted()['select-rule'];

      expect(eventPayload[0]).toEqual(SCAN_EXECUTION_RULES_PIPELINE_KEY);
    });

    it('selects list of branches', async () => {
      const branches = ['main,branch1,branch2'];

      await selectBranches(branches);
      const [eventPayload] = wrapper.emitted().changed;

      expect(eventPayload[0]).toEqual({
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        branches,
      });
    });

    it.each`
      isBranchScope | expectedResult
      ${true}       | ${true}
      ${false}      | ${false}
    `('renders branches input', ({ isBranchScope, expectedResult }) => {
      createComponent({ isBranchScope });

      expect(findBranchTypeSelector().exists()).toBe(expectedResult);
    });

    it('emits array of branches and correct type', async () => {
      await selectBranches(['main', 'branch']);

      expect(wrapper.emitted('changed')).toEqual([
        [{ branches: ['main', 'branch'], type: SCAN_EXECUTION_SCHEDULE_RULE }],
      ]);
    });

    it('trims branch names from white spaces', async () => {
      await selectBranches(['main', 'branch', 'branch2']);

      expect(wrapper.emitted()).toEqual({
        changed: [
          [{ branches: ['main', 'branch', 'branch2'], type: SCAN_EXECUTION_SCHEDULE_RULE }],
        ],
      });
    });

    it('selects correct rule', async () => {
      findRuleTypeDropDown().vm.$emit('select', SCAN_EXECUTION_RULES_PIPELINE_KEY);

      await nextTick();

      expect(wrapper.emitted()).toEqual({
        'select-rule': [[SCAN_EXECUTION_PIPELINE_RULE]],
      });
    });

    it('removes rule', async () => {
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

  describe('branch types', () => {
    it.each(VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS)('should select branch type', (branchType) => {
      createComponent();

      findBranchTypeSelector().vm.$emit('set-branch-type', branchType);

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            type: SCAN_EXECUTION_SCHEDULE_RULE,
            branch_type: branchType,
          },
        ],
      ]);
    });

    it.each`
      type                            | emittedValue
      ${SCAN_EXECUTION_PIPELINE_RULE} | ${['*']}
      ${SCAN_EXECUTION_SCHEDULE_RULE} | ${[]}
    `('should select branches for specific branch type', ({ type, emittedValue }) => {
      createComponent({
        initRule: {
          type,
          branch_type: ALL_PROTECTED_BRANCHES.value,
        },
      });

      expect(findBranchTypeSelector().props('selectedBranchType')).toBe(
        ALL_PROTECTED_BRANCHES.value,
      );

      findBranchTypeSelector().vm.$emit('set-branch-type', SPECIFIC_BRANCHES.value);

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            type,
            branches: emittedValue,
          },
        ],
      ]);
    });
  });
});
