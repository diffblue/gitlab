import { GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import {
  ALL_BRANCHES,
  ALL_PROTECTED_BRANCHES,
  PLACEHOLDER,
} from 'ee/vue_shared/components/branches_selector/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_PROTECTED_BRANCHES } from './mock_data';

const branchNames = (branches = TEST_PROTECTED_BRANCHES) => branches.map((branch) => branch.name);
const addValueToBranches = (branches) => branches.map((b) => ({ ...b, value: b.name }));
const error = new Error('Something went wrong');

describe('Protected Branches Selector', () => {
  let wrapper;
  let closeSpy;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSelectableBranches = () =>
    findListbox()
      .props('items')
      .map((item) => item.name);
  const findAllBranchesOption = () => wrapper.findByTestId('all-branches-option');
  const findAllProtectedBranchesOption = () =>
    wrapper.findByTestId('all-protected-branches-option');

  const createComponent = (props = {}) => {
    wrapper = mountExtended(ProtectedBranchesSelector, {
      propsData: {
        projectId: '1',
        ...props,
      },
      stubs: {
        GlDropdownItem: true,
      },
    });
  };

  beforeEach(() => {
    jest
      .spyOn(Api, 'projectProtectedBranches')
      .mockReturnValue(Promise.resolve(TEST_PROTECTED_BRANCHES));
  });

  describe('default rendering', () => {
    it('renders dropdown', async () => {
      createComponent();
      await waitForPromises();

      expect(findListbox().exists()).toBe(true);
    });

    it('renders dropdown with invalid class if is invalid', async () => {
      createComponent({ isInvalid: true });
      await waitForPromises();

      expect(findListbox().classes('is-invalid')).toBe(true);
    });

    it('displays the protected branches and all branches option', async () => {
      createComponent();
      await nextTick();

      expect(findListbox().props('loading')).toBe(true);
      await waitForPromises();

      expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: false }]]);
      expect(findSelectableBranches()).toStrictEqual(branchNames());
      expect(findListbox().props('loading')).toBe(false);
    });
  });

  describe('selected branch', () => {
    it.each`
      allowAllBranchesOption | allowAllProtectedBranchesOption | multiple | selectedBranches                          | selectedBranchesNames  | branchName
      ${true}                | ${false}                        | ${false} | ${[ALL_BRANCHES]}                         | ${[]}                  | ${ALL_BRANCHES.name}
      ${true}                | ${false}                        | ${false} | ${[]}                                     | ${['development']}     | ${'development'}
      ${true}                | ${false}                        | ${false} | ${[{ id: 1, name: 'main' }]}              | ${[]}                  | ${'main'}
      ${true}                | ${false}                        | ${false} | ${[{ id: 1, name: 'main' }]}              | ${['development']}     | ${'main'}
      ${true}                | ${true}                         | ${false} | ${[ALL_BRANCHES, ALL_PROTECTED_BRANCHES]} | ${[]}                  | ${ALL_BRANCHES.name}
      ${false}               | ${true}                         | ${false} | ${[ALL_PROTECTED_BRANCHES]}               | ${[]}                  | ${ALL_PROTECTED_BRANCHES.name}
      ${false}               | ${false}                        | ${false} | ${[]}                                     | ${[]}                  | ${PLACEHOLDER.name}
      ${true}                | ${true}                         | ${false} | ${null}                                   | ${null}                | ${PLACEHOLDER.name}
      ${true}                | ${false}                        | ${true}  | ${[ALL_BRANCHES]}                         | ${[ALL_BRANCHES.name]} | ${ALL_BRANCHES.name}
    `(
      'with allowAllBranchesOption = $allowAllBranchesOption, allowAllProtectedBranchesOption = $allowAllProtectedBranchesOption, selectedBranches = $selectedBranches, and selectedBranchesNames = $selectedBranchesNames, the selected branch is $branchName',
      async ({
        allowAllBranchesOption,
        allowAllProtectedBranchesOption,
        multiple,
        selectedBranches,
        selectedBranchesNames,
        branchName,
      }) => {
        createComponent({
          allowAllBranchesOption,
          allowAllProtectedBranchesOption,
          multiple,
          selectedBranches,
          selectedBranchesNames,
        });
        await waitForPromises();

        expect(findListbox().props('toggleText')).toBe(branchName);
        if (multiple) {
          expect(findListbox().props('selected')).toStrictEqual([branchName]);
        } else {
          expect(findListbox().props('selected')).toBe(branchName);
        }
      },
    );
  });

  describe.each`
    ALL_OPTION                | findFn                            | prop
    ${ALL_BRANCHES}           | ${findAllBranchesOption}          | ${'allowAllBranchesOption'}
    ${ALL_PROTECTED_BRANCHES} | ${findAllProtectedBranchesOption} | ${'allowAllProtectedBranchesOption'}
  `('$prop', ({ ALL_OPTION, findFn, prop }) => {
    it('does show the option when $prop is true', () => {
      createComponent({
        [prop]: true,
      });

      expect(findFn().exists()).toBe(true);
    });

    it('does not show the option when $prop is false', () => {
      createComponent({
        [prop]: false,
      });

      expect(findFn().exists()).toBe(false);
    });

    it('selects the all branches option if passed in', async () => {
      createComponent({
        [prop]: true,
        selectedBranches: [ALL_OPTION],
      });
      await waitForPromises();

      expect(findListbox().props('toggleText')).toBe(ALL_OPTION.name);
    });

    it('closes the dropdown when clicked', async () => {
      createComponent({
        [prop]: true,
      });
      closeSpy = jest.spyOn(wrapper.vm.$refs.branches, 'close');

      await findFn().vm.$emit('click');

      expect(closeSpy).toHaveBeenCalled();
    });
  });

  describe('single branch', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('emits the correct branch when selected', async () => {
      findListbox().vm.$emit('select', TEST_PROTECTED_BRANCHES[0].name);
      await nextTick();

      expect(wrapper.emitted('input')).toStrictEqual([
        addValueToBranches([TEST_PROTECTED_BRANCHES[0]]),
      ]);
    });

    it('emits the new branch when selected', async () => {
      findListbox().vm.$emit('select', TEST_PROTECTED_BRANCHES[0].name);
      await nextTick();
      findListbox().vm.$emit('select', TEST_PROTECTED_BRANCHES[1].name);
      await nextTick();

      expect(wrapper.emitted('input')[1]).toStrictEqual(
        addValueToBranches([TEST_PROTECTED_BRANCHES[1]]),
      );
    });
  });

  describe('multiple branches', () => {
    beforeEach(async () => {
      createComponent({ multiple: true });
      await waitForPromises();
    });

    it('emits the correct branch when selected', async () => {
      findListbox().vm.$emit('select', [TEST_PROTECTED_BRANCHES[0].name]);
      await nextTick();

      expect(wrapper.emitted('input')).toStrictEqual([
        [addValueToBranches([TEST_PROTECTED_BRANCHES[0]])],
      ]);
    });

    it('emits multiple branches when selected', async () => {
      findListbox().vm.$emit('select', [
        TEST_PROTECTED_BRANCHES[0].name,
        TEST_PROTECTED_BRANCHES[1].name,
      ]);
      await nextTick();

      expect(wrapper.emitted('input')[0]).toStrictEqual([
        addValueToBranches([TEST_PROTECTED_BRANCHES[0], TEST_PROTECTED_BRANCHES[1]]),
      ]);
    });

    it('emits one branch when a branch is deselected', async () => {
      findListbox().vm.$emit('select', []);
      await nextTick();

      expect(wrapper.emitted('input')[0]).toStrictEqual([addValueToBranches([])]);
    });
  });

  describe('footer', () => {
    it('emits "null" if it is already selected', async () => {
      createComponent();
      await waitForPromises();
      await findAllBranchesOption().vm.$emit('click');

      expect(wrapper.emitted('input')).toStrictEqual([[null]]);
    });

    it('emits the correct branch when the footer is clicked for single branches', async () => {
      createComponent({ allowAllProtectedBranchesOption: true });
      await waitForPromises();
      await findAllProtectedBranchesOption().vm.$emit('click');

      expect(wrapper.emitted('input')).toStrictEqual([
        addValueToBranches([ALL_PROTECTED_BRANCHES]),
      ]);
    });

    it('emits the correct branch when the footer is clicked for multiple branches', async () => {
      createComponent({ allowAllProtectedBranchesOption: true, multiple: true });
      await waitForPromises();
      await findAllProtectedBranchesOption().vm.$emit('click');

      expect(wrapper.emitted('input')).toStrictEqual([
        [addValueToBranches([ALL_PROTECTED_BRANCHES])],
      ]);
    });
  });

  describe('when fetching the branch list fails', () => {
    beforeEach(() => {
      jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
      createComponent();
    });

    it('emits the `apiError` event', () => {
      expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: true, error }]]);
    });

    it('returns just the all branch dropdown item', () => {
      expect(findSelectableBranches()).toStrictEqual([]);
    });
  });
});
