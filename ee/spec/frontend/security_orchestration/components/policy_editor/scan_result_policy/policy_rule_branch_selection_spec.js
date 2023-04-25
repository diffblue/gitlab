import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PolicyRuleBranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_branch_selection.vue';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { ALL_PROTECTED_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';
import { SPECIFIC_BRANCHES } from 'ee/security_orchestration/components/policy_editor/constants';

describe('PolicyRuleBranchSelection', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const DEFAULT_RULE = {
    branches: [],
  };

  const UPDATED_RULE = {
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
  };

  const factory = (propsData = {}, provide = {}) => {
    wrapper = shallowMountExtended(PolicyRuleBranchSelection, {
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

  const findProjectLevelProtectedBranchesSelector = () =>
    wrapper.findComponent(ProtectedBranchesSelector);
  const findGroupLevelProtectedBranchesSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSpecificBranchInput = () => wrapper.findComponent(GlFormInput);
  const findBranchesLabel = () => wrapper.findByTestId('branches-label');

  describe('project-level', () => {
    describe('default', () => {
      beforeEach(() => {
        factory();
      });

      it.each`
        title         | component                                      | findFn                                       | output
        ${'does'}     | ${'project-level protected branches selector'} | ${findProjectLevelProtectedBranchesSelector} | ${true}
        ${'does not'} | ${'group-level protected branches selector'}   | ${findGroupLevelProtectedBranchesSelector}   | ${false}
      `('$title render the $component', ({ findFn, output }) => {
        expect(findFn().exists()).toBe(output);
      });

      it('renders default selected branch', () => {
        expect(
          findProjectLevelProtectedBranchesSelector().props('selectedBranchesNames'),
        ).toStrictEqual([]);
      });

      it('does render branches label when a branch is selected', async () => {
        factory({ initRule: UPDATED_RULE });
        await nextTick();
        expect(findBranchesLabel().exists()).toBe(true);
      });
    });

    describe('protected branches selector', () => {
      beforeEach(async () => {
        factory();
        findProjectLevelProtectedBranchesSelector().vm.$emit('input', PROTECTED_BRANCHES_MOCK[0]);
        await nextTick();
      });

      it('triggers a changed event with the updated branches', () => {
        expect(wrapper.emitted().changed).toEqual([
          [expect.objectContaining({ branches: UPDATED_RULE.branches })],
        ]);
      });

      it('does not add to branches if "All Protected Branches" is selected', async () => {
        findProjectLevelProtectedBranchesSelector().vm.$emit('input', ALL_PROTECTED_BRANCHES);
        await nextTick();
        expect(wrapper.emitted().changed[1]).toEqual([expect.objectContaining({ branches: [] })]);
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
        ${'does not'} | ${'project-level protected branches selector'} | ${findProjectLevelProtectedBranchesSelector} | ${false}
        ${'does'}     | ${'group-level protected branches selector'}   | ${findGroupLevelProtectedBranchesSelector}   | ${true}
        ${'does not'} | ${'group-level specific branches input'}       | ${findSpecificBranchInput}                   | ${false}
      `('$title render the $component', ({ findFn, output }) => {
        expect(findFn().exists()).toBe(output);
      });
    });

    describe('specific branches default state', () => {
      it.each`
        initRule        | expectedResult
        ${DEFAULT_RULE} | ${ALL_PROTECTED_BRANCHES.value}
        ${UPDATED_RULE} | ${SPECIFIC_BRANCHES.value}
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

          expect(findGroupLevelProtectedBranchesSelector().props('selected')).toBe(expectedResult);
        },
      );
    });

    describe('specific branches input', () => {
      beforeEach(async () => {
        factory({}, { namespaceType: NAMESPACE_TYPES.GROUP });
        findGroupLevelProtectedBranchesSelector().vm.$emit('select', 'SPECIFIC_BRANCHES');
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
    });
  });
});
