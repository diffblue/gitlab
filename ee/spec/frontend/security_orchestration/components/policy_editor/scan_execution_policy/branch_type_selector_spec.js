import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchTypeSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/branch_type_selector.vue';
import {
  ALL_BRANCHES,
  GROUP_DEFAULT_BRANCHES,
  ALL_PROTECTED_BRANCHES,
  SPECIFIC_BRANCHES,
  SCAN_EXECUTION_BRANCH_TYPE_OPTIONS,
} from 'ee/security_orchestration/components/policy_editor/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('BranchTypeSelector', () => {
  let wrapper;

  const BRANCH_TYPE_VALUES = [
    ALL_BRANCHES.value,
    ALL_PROTECTED_BRANCHES.value,
    GROUP_DEFAULT_BRANCHES.value,
  ];

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(BranchTypeSelector, {
      propsData,
      provide: {
        namespaceType: NAMESPACE_TYPES.GROUP,
        ...provide,
      },
    });
  };

  const findBranchTypeListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findBranchesInput = () => wrapper.findComponent(GlFormInput);

  it('should render specific branches by default', () => {
    createComponent();

    expect(findBranchTypeListbox().props('selected')).toBe(SPECIFIC_BRANCHES.value);
    expect(findBranchesInput().exists()).toBe(true);
  });

  it.each([NAMESPACE_TYPES.GROUP, NAMESPACE_TYPES.PROJECT])(
    'should render specific branches for group and project',
    (namespaceType) => {
      createComponent({
        provide: { namespaceType },
      });

      expect(findBranchTypeListbox().props('items')).toEqual(
        SCAN_EXECUTION_BRANCH_TYPE_OPTIONS(namespaceType),
      );
    },
  );

  it.each(BRANCH_TYPE_VALUES)('should render different branch types', (selectedBranchType) => {
    createComponent({
      propsData: {
        selectedBranchType,
      },
    });

    expect(findBranchTypeListbox().props('selected')).toBe(selectedBranchType);
    expect(findBranchesInput().exists()).toBe(false);
  });

  it.each(BRANCH_TYPE_VALUES)('should change branch type', (selectedBranchType) => {
    createComponent();

    findBranchTypeListbox().vm.$emit('select', selectedBranchType);

    expect(wrapper.emitted('set-branch-type')).toEqual([[selectedBranchType]]);
  });

  it('should change branches', () => {
    createComponent();

    findBranchesInput().vm.$emit('input', 'main, release');

    expect(wrapper.emitted('input')).toEqual([[['main', 'release']]]);
  });
});
