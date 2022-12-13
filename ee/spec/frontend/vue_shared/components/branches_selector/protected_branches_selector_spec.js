import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Api from 'ee/api';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import {
  ALL_BRANCHES,
  ALL_PROTECTED_BRANCHES,
  PLACEHOLDER,
} from 'ee/vue_shared/components/branches_selector/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_BRANCHES_SELECTIONS, TEST_PROJECT_ID, TEST_PROTECTED_BRANCHES } from './mock_data';

const allBranchOptions = [ALL_BRANCHES, ALL_PROTECTED_BRANCHES, ...TEST_PROTECTED_BRANCHES];
const branchNames = (branches = TEST_BRANCHES_SELECTIONS) => branches.map((branch) => branch.name);
const protectedBranchNames = () => TEST_PROTECTED_BRANCHES.map((branch) => branch.name);
const error = new Error('Something went wrong');

describe('Protected Branches Selector', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findSelectableBranches = () => findDropdownItems().wrappers.map((item) => item.text());
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(ProtectedBranchesSelector, {
      propsData: {
        projectId: '1',
        ...props,
      },
    });
  };

  beforeEach(() => {
    jest
      .spyOn(Api, 'projectProtectedBranches')
      .mockReturnValue(Promise.resolve(TEST_PROTECTED_BRANCHES));
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Initialization', () => {
    it('renders dropdown', async () => {
      createComponent();
      await waitForPromises();

      expect(findDropdown().exists()).toBe(true);
    });

    it('renders dropdown with invalid class if is invalid', async () => {
      createComponent({ isInvalid: true });
      await waitForPromises();

      expect(findDropdown().classes('is-invalid')).toBe(true);
    });

    it.each`
      allowAllBranchesOption | allowAllProtectedBranchesOption | selectedBranches                          | selectedBranchesNames | branchName
      ${true}                | ${false}                        | ${[ALL_BRANCHES]}                         | ${[]}                 | ${ALL_BRANCHES.name}
      ${true}                | ${false}                        | ${[ALL_PROTECTED_BRANCHES]}               | ${[]}                 | ${ALL_BRANCHES.name}
      ${true}                | ${false}                        | ${[]}                                     | ${['development']}    | ${'development'}
      ${true}                | ${false}                        | ${[{ id: 1, name: 'main' }]}              | ${[]}                 | ${'main'}
      ${true}                | ${false}                        | ${[{ id: 1, name: 'main' }]}              | ${['development']}    | ${'main'}
      ${true}                | ${true}                         | ${[ALL_BRANCHES, ALL_PROTECTED_BRANCHES]} | ${[]}                 | ${ALL_BRANCHES.name}
      ${false}               | ${true}                         | ${[ALL_PROTECTED_BRANCHES]}               | ${[]}                 | ${ALL_PROTECTED_BRANCHES.name}
      ${false}               | ${false}                        | ${[]}                                     | ${[]}                 | ${PLACEHOLDER.name}
    `(
      'with allowAllBranchesOption set to $allowAllBranchesOption and allowAllProtectedBranchesOption set to $allowAllProtectedBranchesOption and selectedBranches set to $selectedBranches and selectedBranchesNames set to $selectedBranchesNames the item checked is: $branchName',
      async ({
        allowAllBranchesOption,
        allowAllProtectedBranchesOption,
        selectedBranches,
        selectedBranchesNames,
        branchName,
      }) => {
        createComponent({
          selectedBranches,
          selectedBranchesNames,
          allowAllBranchesOption,
          allowAllProtectedBranchesOption,
        });
        await waitForPromises();

        expect(findDropdown().props('text')).toBe(branchName);
        if (selectedBranches.length > 0 || selectedBranchesNames.length > 0)
          expect(
            findDropdownItems()
              .filter((item) => item.text() === branchName)
              .at(0)
              .props('isChecked'),
          ).toBe(true);
      },
    );

    it('displays all the protected branches and all branches', async () => {
      createComponent();
      await nextTick();

      expect(findDropdown().props('loading')).toBe(true);
      await waitForPromises();

      expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: false }]]);
      expect(findSelectableBranches()).toStrictEqual(branchNames());
      expect(findDropdown().props('loading')).toBe(false);
    });

    describe('with allow all branches option', () => {
      it('set to true', async () => {
        createComponent({
          allowAllBranchesOption: true,
        });
        await waitForPromises();

        expect(findDropdownItems().filter((item) => item.text() === ALL_BRANCHES.name).length).toBe(
          1,
        );
      });

      it('set to false', async () => {
        createComponent({
          allowAllBranchesOption: false,
        });
        await waitForPromises();

        expect(findDropdownItems().filter((item) => item.text() === ALL_BRANCHES.name).length).toBe(
          0,
        );
      });
    });

    describe('with allow all protected branches option', () => {
      it('selects the all protected branches option if passed in', async () => {
        createComponent({
          allowAllProtectedBranchesOption: true,
          selectedBranches: [ALL_PROTECTED_BRANCHES],
        });
        await waitForPromises();

        expect(findDropdown().props('text')).toBe(ALL_PROTECTED_BRANCHES.name);
        expect(
          findDropdownItems()
            .filter((item) => item.text() === ALL_PROTECTED_BRANCHES.name)
            .at(0)
            .props('isChecked'),
        ).toBe(true);
      });

      it('displays all the protected branches, all branches, and all protected branches', async () => {
        createComponent({ allowAllProtectedBranchesOption: true });
        await nextTick();

        expect(findDropdown().props('loading')).toBe(true);
        await waitForPromises();

        expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: false }]]);
        expect(findSelectableBranches()).toStrictEqual(branchNames(allBranchOptions));
        expect(findDropdown().props('loading')).toBe(false);
      });
    });

    describe('when fetching the branch list fails', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        createComponent({});
      });

      it('emits the `apiError` event', () => {
        expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: true, error }]]);
      });

      it('returns just the all branch dropdown item', () => {
        expect(findSelectableBranches()).toStrictEqual([ALL_BRANCHES.name]);
      });
    });
  });

  describe('with search term', () => {
    it('fetches protected branches with search term', async () => {
      const term = 'lorem';

      createComponent({}, mount);

      findSearch().vm.$emit('input', term);
      await nextTick();

      expect(findSearch().props('isLoading')).toBe(true);

      await waitForPromises();

      expect(Api.projectProtectedBranches).toHaveBeenCalledWith(TEST_PROJECT_ID, term);
      expect(wrapper.emitted('apiError')).toStrictEqual([
        [{ hasErrored: false }],
        [{ hasErrored: false }],
      ]);
      expect(findSearch().props('isLoading')).toBe(false);
    });

    it('fetches protected branches with no all branches if there is a search', async () => {
      createComponent({}, mount);

      findSearch().vm.$emit('input', 'main');
      await waitForPromises();

      expect(findSelectableBranches()).toStrictEqual(protectedBranchNames());
    });

    it('fetches protected branches with all branches if search contains term "all"', async () => {
      createComponent({}, mount);

      findSearch().vm.$emit('input', 'all');
      await waitForPromises();

      expect(findSelectableBranches()).toStrictEqual(branchNames());
    });

    describe('with allow all protected branches option', () => {
      it('fetches protected branches with all branches if search contains term "all"', async () => {
        createComponent({ allowAllProtectedBranchesOption: true }, mount);

        findSearch().vm.$emit('input', 'all');
        await waitForPromises();

        expect(findSelectableBranches()).toStrictEqual(branchNames(allBranchOptions));
      });

      describe('when fetching the branch list fails while searching', () => {
        beforeEach(() => {
          createComponent({ allowAllProtectedBranchesOption: true }, mount);

          return waitForPromises();
        });

        it('emits the `apiError` event and returns all branches and all protected branches when searching for "all"', async () => {
          jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
          findSearch().vm.$emit('input', 'all');

          await waitForPromises();

          expect(wrapper.emitted('apiError')).toStrictEqual([
            [{ hasErrored: false }],
            [{ hasErrored: true, error }],
          ]);
          expect(findSelectableBranches()).toStrictEqual([
            ALL_BRANCHES.name,
            ALL_PROTECTED_BRANCHES.name,
          ]);
        });
      });
    });

    describe('when fetching the branch list fails while searching', () => {
      beforeEach(() => {
        createComponent({}, mount);

        return waitForPromises();
      });

      it('emits the `apiError` event and returns no items when searching for a term', async () => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        findSearch().vm.$emit('input', 'main');

        await waitForPromises();

        expect(wrapper.emitted('apiError')).toStrictEqual([
          [{ hasErrored: false }],
          [{ hasErrored: true, error }],
        ]);
        expect(findDropdownItems()).toHaveLength(0);
      });

      it('emits the `apiError` event and returns all branches when searching for "all"', async () => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        findSearch().vm.$emit('input', 'all');

        await waitForPromises();

        expect(wrapper.emitted('apiError')).toStrictEqual([
          [{ hasErrored: false }],
          [{ hasErrored: true, error }],
        ]);
        expect(findSelectableBranches()).toStrictEqual([ALL_BRANCHES.name]);
      });
    });
  });

  it('when the branch is changed it sets the isChecked property and emits the input event', async () => {
    createComponent();

    await waitForPromises();
    await findDropdownItems().at(1).vm.$emit('click');

    expect(findDropdownItems().at(1).props('isChecked')).toBe(true);
    expect(wrapper.emitted('input')).toStrictEqual([[TEST_PROTECTED_BRANCHES[0]]]);
  });
});
