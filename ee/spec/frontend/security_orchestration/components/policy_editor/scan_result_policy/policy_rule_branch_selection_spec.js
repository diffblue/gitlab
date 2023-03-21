import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PolicyRuleBranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_branch_selection.vue';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { ALL_PROTECTED_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';

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

  const findBranches = () => wrapper.findComponent(ProtectedBranchesSelector);
  const findBranchesLabel = () => wrapper.findByTestId('branches-label');
  const findGroupLevelBranches = () => wrapper.findByTestId('group-level-branch');

  describe('initial rendering', () => {
    beforeEach(() => {
      factory();
    });

    it('renders one field for each attribute of the rule', () => {
      expect(findBranches().exists()).toBe(true);
    });

    it('does not render branches label when targeting all branches', () => {
      expect(findBranchesLabel().exists()).toBe(false);
    });

    it('renders default selected branch', () => {
      expect(findBranches().props('selectedBranchesNames')).toStrictEqual([]);
    });
  });

  describe('when editing any attribute of the rule', () => {
    it('triggers a changed event (by findBranches) with the updated rule', async () => {
      factory();
      await nextTick();
      findBranches().vm.$emit('input', PROTECTED_BRANCHES_MOCK[0]);
      await nextTick();

      expect(wrapper.emitted().changed).toEqual([
        [expect.objectContaining({ branches: UPDATED_RULE.branches })],
      ]);
    });

    it('does not add to branches if "All Protected Branches" is selected', async () => {
      factory();
      await nextTick();
      findBranches().vm.$emit('input', PROTECTED_BRANCHES_MOCK[0]);
      await nextTick();
      findBranches().vm.$emit('input', ALL_PROTECTED_BRANCHES);
      await nextTick();
      expect(wrapper.emitted().changed[1]).toEqual([expect.objectContaining({ branches: [] })]);
    });
  });

  it('does render branches label when a branch is selected', async () => {
    factory({ initRule: UPDATED_RULE });
    await nextTick();
    expect(findBranchesLabel().exists()).toBe(true);
  });

  describe('when namespaceType is other than project', () => {
    it('does not display group level branches', () => {
      factory({}, { namespaceType: NAMESPACE_TYPES.GROUP });

      expect(findBranches().exists()).toBe(true);
      expect(findGroupLevelBranches().exists()).toBe(false);
    });

    describe('when groupLevelScanResultPolicies feature flag is enabled', () => {
      it('displays group level branches', () => {
        factory(
          {},
          {
            namespaceType: NAMESPACE_TYPES.GROUP,
            glFeatures: { groupLevelScanResultPolicies: true },
          },
        );

        expect(findBranches().exists()).toBe(false);
        expect(findGroupLevelBranches().exists()).toBe(true);
      });

      it('triggers a changed event with the updated rule', async () => {
        factory(
          {},
          {
            namespaceType: NAMESPACE_TYPES.GROUP,
            glFeatures: { groupLevelScanResultPolicies: true },
          },
        );

        const INPUT_BRANCHES = 'main, test';
        const EXPECTED_BRANCHES = ['main', 'test'];
        findGroupLevelBranches().vm.$emit('input', INPUT_BRANCHES);

        await nextTick();

        expect(wrapper.emitted().changed).toEqual([
          [expect.objectContaining({ branches: EXPECTED_BRANCHES })],
        ]);
      });

      it('group level branches is invalid when empty', () => {
        factory(
          { initRule: { ...DEFAULT_RULE, branches: [''] } },
          {
            namespaceType: NAMESPACE_TYPES.GROUP,
            glFeatures: { groupLevelScanResultPolicies: true },
          },
        );

        expect(findGroupLevelBranches().props('state')).toBe(undefined);
      });
    });
  });
});
