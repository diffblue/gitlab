import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Api from 'ee/api';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import waitForPromises from 'helpers/wait_for_promises';
import {
  TEST_DEFAULT_BRANCH,
  TEST_BRANCHES_SELECTIONS,
  TEST_PROJECT_ID,
  TEST_PROTECTED_BRANCHES,
} from './mock_data';

const branchNames = () => TEST_BRANCHES_SELECTIONS.map((branch) => branch.name);
const protectedBranchNames = () => TEST_PROTECTED_BRANCHES.map((branch) => branch.name);
const error = new Error('Something went wrong');

describe('Protected Branches Selector', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
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
      selectedBranches             | selectedBranchesNames | branchName
      ${[]}                        | ${['development']}    | ${'development'}
      ${[{ id: 1, name: 'main' }]} | ${[]}                 | ${'main'}
      ${[{ id: 1, name: 'main' }]} | ${['development']}    | ${'main'}
    `(
      'with selectedBranches and selectedBranchesNames set to $selectedBranches and $selectedBranchesNames the item checked is: $branchName',
      async ({ selectedBranches, selectedBranchesNames, branchName }) => {
        createComponent({
          selectedBranches,
          selectedBranchesNames,
        });
        await waitForPromises();

        expect(findDropdown().props('text')).toBe(branchName);
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
      expect(findDropdownItems()).toHaveLength(branchNames().length);
      expect(findDropdown().props('loading')).toBe(false);
    });

    describe('when fetching the branch list fails', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        createComponent({});
      });

      it('emits the `apiError` event', () => {
        expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: true, error }]]);
      });

      it('returns just the all branch dropdown items', () => {
        expect(findDropdownItems()).toHaveLength(1);
        expect(findDropdownItems().at(0).text()).toBe(TEST_DEFAULT_BRANCH.name);
      });
    });
  });

  describe('with search term', () => {
    beforeEach(() => {
      createComponent({}, mount);
      return waitForPromises();
    });

    it('fetches protected branches with search term', async () => {
      const term = 'lorem';

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
      findSearch().vm.$emit('input', 'main');
      await waitForPromises();

      expect(findDropdownItems()).toHaveLength(protectedBranchNames().length);
    });

    it('fetches protected branches with all branches if search contains term "all"', async () => {
      findSearch().vm.$emit('input', 'all');
      await waitForPromises();

      expect(findDropdownItems()).toHaveLength(branchNames().length);
    });

    describe('when fetching the branch list fails while searching', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        findSearch().vm.$emit('input', 'main');

        return waitForPromises();
      });

      it('emits the `apiError` event', () => {
        expect(wrapper.emitted('apiError')).toStrictEqual([
          [{ hasErrored: false }],
          [{ hasErrored: true, error }],
        ]);
      });

      it('returns no dropdown items', () => {
        expect(findDropdownItems()).toHaveLength(0);
      });
    });

    describe('when fetching the branch list fails while searching for the term "all"', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        findSearch().vm.$emit('input', 'all');

        return waitForPromises();
      });

      it('emits the `apiError` event', () => {
        expect(wrapper.emitted('apiError')).toStrictEqual([
          [{ hasErrored: false }],
          [{ hasErrored: true, error }],
        ]);
      });

      it('returns just the all branch dropdown item', () => {
        expect(findDropdownItems()).toHaveLength(1);
        expect(findDropdownItems().at(0).text()).toBe(TEST_DEFAULT_BRANCH.name);
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
