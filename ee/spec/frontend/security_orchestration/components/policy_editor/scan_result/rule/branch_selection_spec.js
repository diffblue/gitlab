import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result/rule/branch_selection.vue';
import ProtectedBranchesDropdown from 'ee/security_orchestration/components/policy_editor/protected_branches_dropdown.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  ALL_PROTECTED_BRANCHES,
  GROUP_DEFAULT_BRANCHES,
  SCAN_EXECUTION_BRANCH_TYPE_OPTIONS,
  SCAN_RESULT_BRANCH_TYPE_OPTIONS,
  SPECIFIC_BRANCHES,
} from 'ee/security_orchestration/components/policy_editor/constants';
import {
  SCAN_FINDING,
  LICENSE_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';

describe('BranchSelection', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const DEFAULT_RULE = {
    branches: [],
  };

  const RULE_WITH_BRANCH_TYPE = {
    branch_type: 'default',
  };

  const UPDATED_SCAN_FINDING_RULE = {
    type: SCAN_FINDING,
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
  };

  const UPDATED_LICENSE_FINDING_RULE = {
    type: LICENSE_FINDING,
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
  };

  const RULE_WITHOUT_TYPE = {
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
  };

  const factory = (propsData = {}, provide = {}) => {
    wrapper = shallowMountExtended(BranchSelection, {
      propsData: {
        initRule: DEFAULT_RULE,
        ...propsData,
      },
      provide: {
        namespaceId: '1',
        namespaceType: NAMESPACE_TYPES.PROJECT,
        ...provide,
      },
    });
  };

  const findProjectLevelProtectedBranchesDropdown = () =>
    wrapper.findComponent(ProtectedBranchesDropdown);
  const findProtectedBranchesSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSpecificBranchInput = () => wrapper.findComponent(GlFormInput);
  const findBranchesLabel = () => wrapper.findByTestId('branches-label');

  describe('project-level', () => {
    describe('default', () => {
      beforeEach(() => {
        factory();
      });

      it.each`
        title         | component                                      | findFn                                       | output
        ${'does'}     | ${'project-level protected branches selector'} | ${findProjectLevelProtectedBranchesDropdown} | ${false}
        ${'does not'} | ${'group-level protected branches selector'}   | ${findProtectedBranchesSelector}             | ${true}
      `('$title render the $component', ({ findFn, output }) => {
        expect(findFn().exists()).toBe(output);
      });

      it('renders default selected branch', async () => {
        findProtectedBranchesSelector().vm.$emit('select', SPECIFIC_BRANCHES.id);
        await nextTick();

        expect(findProjectLevelProtectedBranchesDropdown().props('selected')).toStrictEqual([]);
      });

      it('does render branches label when a branch is selected', async () => {
        factory({ initRule: UPDATED_SCAN_FINDING_RULE });
        await nextTick();
        expect(findBranchesLabel().exists()).toBe(true);
      });
    });

    describe('protected branches selector', () => {
      beforeEach(() => {
        factory();
      });

      it('does not render branch selector for all protected branches', () => {
        expect(findProjectLevelProtectedBranchesDropdown().exists()).toBe(false);
      });

      it('does not renders branch selector for specific branches mode', async () => {
        findProtectedBranchesSelector().vm.$emit('select', SPECIFIC_BRANCHES.id);
        await nextTick();

        expect(findProjectLevelProtectedBranchesDropdown().exists()).toBe(true);
      });

      it('triggers a changed event with the updated branches', async () => {
        findProtectedBranchesSelector().vm.$emit('select', SPECIFIC_BRANCHES.id);
        await nextTick();

        await findProjectLevelProtectedBranchesDropdown().vm.$emit('input', [
          PROTECTED_BRANCHES_MOCK[0].name,
        ]);

        expect(wrapper.emitted('changed')).toEqual([
          [expect.objectContaining({ branches: UPDATED_SCAN_FINDING_RULE.branches })],
        ]);
      });

      it('does not show branches label if "All Protected Branches" is selected', () => {
        expect(findBranchesLabel().exists()).toBe(false);
      });
    });
  });

  describe('group-level', () => {
    describe('default', () => {
      beforeEach(() => {
        factory({}, { namespaceType: NAMESPACE_TYPES.GROUP });
      });

      it.each`
        title         | component                                      | findFn                                       | output
        ${'does not'} | ${'project-level protected branches selector'} | ${findProjectLevelProtectedBranchesDropdown} | ${false}
        ${'does'}     | ${'group-level protected branches selector'}   | ${findProtectedBranchesSelector}             | ${true}
        ${'does not'} | ${'group-level specific branches input'}       | ${findSpecificBranchInput}                   | ${false}
      `('$title render the $component', ({ findFn, output }) => {
        expect(findFn().exists()).toBe(output);
      });
    });

    describe('specific branches default state', () => {
      it.each`
        initRule                        | expectedResult
        ${DEFAULT_RULE}                 | ${ALL_PROTECTED_BRANCHES.value}
        ${RULE_WITH_BRANCH_TYPE}        | ${GROUP_DEFAULT_BRANCHES.value}
        ${UPDATED_SCAN_FINDING_RULE}    | ${SPECIFIC_BRANCHES.value}
        ${UPDATED_LICENSE_FINDING_RULE} | ${SPECIFIC_BRANCHES.value}
        ${RULE_WITHOUT_TYPE}            | ${ALL_PROTECTED_BRANCHES.value}
      `(
        'should select branch selector based on selected branches for a group',
        ({ initRule, expectedResult }) => {
          factory(
            {
              initRule,
            },
            {
              namespaceType: NAMESPACE_TYPES.GROUP,
            },
          );

          expect(findProtectedBranchesSelector().props('selected')).toBe(expectedResult);
        },
      );
    });

    describe('specific branches input', () => {
      beforeEach(async () => {
        factory({}, { namespaceType: NAMESPACE_TYPES.GROUP });
        await findProtectedBranchesSelector().vm.$emit('select', 'SPECIFIC_BRANCHES');
        await nextTick();
      });

      it('shows the specific branch input when "Specific Branches" is selected', () => {
        expect(findSpecificBranchInput().exists()).toBe(true);
      });

      it('triggers a changed event with the updated rule', async () => {
        const INPUT_BRANCHES = 'main, release, staging';
        const EXPECTED_BRANCHES = ['main', 'release', 'staging'];
        findSpecificBranchInput().vm.$emit('input', INPUT_BRANCHES);
        await nextTick();

        expect(wrapper.emitted().changed).toEqual([
          [expect.objectContaining({ branches: EXPECTED_BRANCHES })],
        ]);
      });

      it('does not trigger changes with "*" branches', async () => {
        const INPUT_BRANCHES = 'main, *';
        const EXPECTED_BRANCHES = ['main'];
        findSpecificBranchInput().vm.$emit('input', INPUT_BRANCHES);
        await nextTick();

        expect(wrapper.emitted().changed).toEqual([
          [expect.objectContaining({ branches: EXPECTED_BRANCHES })],
        ]);
      });

      it('updates the branches appropriately when "All Protected Branches" is selected', async () => {
        const groupLevelProtectedBranchesSelector = findProtectedBranchesSelector();
        await groupLevelProtectedBranchesSelector.vm.$emit('select', ALL_PROTECTED_BRANCHES.text);
        expect(groupLevelProtectedBranchesSelector.props('selected')).toBe(
          ALL_PROTECTED_BRANCHES.text,
        );
      });
    });

    describe('options', () => {
      it.each`
        branchTypes
        ${SCAN_EXECUTION_BRANCH_TYPE_OPTIONS()}
        ${SCAN_RESULT_BRANCH_TYPE_OPTIONS()}
      `('should accept different branch type options', ({ branchTypes }) => {
        factory({
          branchTypes,
        });

        expect(findProtectedBranchesSelector().props('items')).toEqual(branchTypes);
      });
    });

    describe('branch type selection', () => {
      it('should emit rule with branches for specific branches', () => {
        factory();

        expect(findProtectedBranchesSelector().props('selected')).toBe(
          ALL_PROTECTED_BRANCHES.value,
        );

        findProtectedBranchesSelector().vm.$emit('select', SPECIFIC_BRANCHES.value);

        expect(wrapper.emitted('set-branch-type')).toEqual([
          [expect.objectContaining({ branches: [] })],
        ]);
        expect(wrapper.emitted('set-branch-type')).not.toEqual([
          [expect.objectContaining({ branch_type: '' })],
        ]);
      });

      it.each`
        initRule                     | expectedResult
        ${DEFAULT_RULE}              | ${'protected'}
        ${RULE_WITH_BRANCH_TYPE}     | ${'default'}
        ${UPDATED_SCAN_FINDING_RULE} | ${'SPECIFIC_BRANCHES'}
      `('can display previously saved branch types', ({ initRule, expectedResult }) => {
        factory({
          initRule,
        });

        expect(findProtectedBranchesSelector().props('selected')).toBe(expectedResult);
      });
    });

    describe('error handling', () => {
      it('should emit error when protected branch dropdown fails', async () => {
        factory();
        await findProtectedBranchesSelector().vm.$emit('select', 'SPECIFIC_BRANCHES');

        const error = new Error('failed-request');
        findProjectLevelProtectedBranchesDropdown().vm.$emit('error', {
          hasError: true,
          error,
        });

        expect(wrapper.emitted('error')).toHaveLength(1);
        expect(wrapper.emitted('error')).toEqual([[error]]);
      });
    });
  });
});
