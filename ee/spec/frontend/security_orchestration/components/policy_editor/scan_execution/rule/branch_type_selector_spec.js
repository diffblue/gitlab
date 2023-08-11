import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchTypeSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/rule/branch_type_selector.vue';
import {
  SPECIFIC_BRANCHES,
  SCAN_EXECUTION_BRANCH_TYPE_OPTIONS,
  VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS,
} from 'ee/security_orchestration/components/policy_editor/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('BranchTypeSelector', () => {
  let wrapper;

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

  it.each(VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS)(
    'should render different branch types',
    (selectedBranchType) => {
      createComponent({
        propsData: {
          selectedBranchType,
        },
      });

      expect(findBranchTypeListbox().props('selected')).toBe(selectedBranchType);
      expect(findBranchesInput().exists()).toBe(false);
    },
  );

  it.each(VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS)(
    'should change branch type',
    (selectedBranchType) => {
      createComponent();

      findBranchTypeListbox().vm.$emit('select', selectedBranchType);

      expect(wrapper.emitted('set-branch-type')).toEqual([[selectedBranchType]]);
    },
  );

  it('should change branches', () => {
    createComponent();

    findBranchesInput().vm.$emit('input', 'main, release');

    expect(wrapper.emitted('input')).toEqual([[['main', 'release']]]);
  });
});
