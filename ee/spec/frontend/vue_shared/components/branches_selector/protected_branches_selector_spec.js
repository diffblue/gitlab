import { GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
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
const addValueToBranches = (branches) => branches.map((b) => ({ ...b, value: b.name }));
const protectedBranchNames = () => TEST_PROTECTED_BRANCHES.map((branch) => branch.name);
const error = new Error('Something went wrong');

describe('Protected Branches Selector', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSelectableBranches = () =>
    findListbox()
      .props('items')
      .map((item) => item.name);

  const createComponent = (props = {}) => {
    wrapper = mount(ProtectedBranchesSelector, {
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

  describe('Initialization', () => {
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
      'with allowAllBranchesOption set to $allowAllBranchesOption and allowAllProtectedBranchesOption set to $allowAllProtectedBranchesOption and selectedBranches set to $selectedBranches and selectedBranchesNames set to $selectedBranchesNames, the selected branch is $branchName',
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

        expect(findListbox().props('toggleText')).toBe(branchName);
      },
    );

    it('displays all the protected branches and all branches', async () => {
      createComponent();
      await nextTick();

      expect(findListbox().props('loading')).toBe(true);
      await waitForPromises();

      expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: false }]]);
      expect(findSelectableBranches()).toStrictEqual(branchNames());
      expect(findListbox().props('loading')).toBe(false);
    });

    it('when the branch is changed it emits the input event', async () => {
      createComponent();

      await waitForPromises();
      findListbox().vm.$emit('select', TEST_PROTECTED_BRANCHES[0].name);
      await nextTick();

      expect(wrapper.emitted('input')).toStrictEqual([
        addValueToBranches([TEST_PROTECTED_BRANCHES[0]]),
      ]);
    });

    describe('with allow all branches option', () => {
      describe('set to true', () => {
        it('shows the allow all option', async () => {
          createComponent({
            allowAllBranchesOption: true,
          });
          await waitForPromises();

          expect(
            findListbox()
              .props('items')
              .findIndex((b) => b.id === ALL_BRANCHES.id),
          ).toBeGreaterThan(-1);
        });
      });

      describe('set to false', () => {
        it('does not show the allow all option', async () => {
          createComponent({
            allowAllBranchesOption: false,
          });
          await waitForPromises();

          expect(
            findListbox()
              .props('items')
              .findIndex((b) => b.id === ALL_BRANCHES.id),
          ).toBe(-1);
        });
      });
    });

    describe('with allow all protected branches option', () => {
      it('selects the all protected branches option if passed in', async () => {
        createComponent({
          allowAllProtectedBranchesOption: true,
          selectedBranches: [ALL_PROTECTED_BRANCHES],
        });
        await waitForPromises();

        expect(findListbox().props('toggleText')).toBe(ALL_PROTECTED_BRANCHES.name);
      });

      it('displays all the protected branches, all branches, and all protected branches', async () => {
        createComponent({ allowAllProtectedBranchesOption: true });
        await nextTick();

        expect(findListbox().props('loading')).toBe(true);
        await waitForPromises();

        expect(wrapper.emitted('apiError')).toStrictEqual([[{ hasErrored: false }]]);
        expect(findSelectableBranches()).toStrictEqual(branchNames(allBranchOptions));
        expect(findListbox().props('loading')).toBe(false);
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
        expect(findSelectableBranches()).toStrictEqual([ALL_BRANCHES.name]);
      });
    });
  });

  describe('with search term', () => {
    it('fetches protected branches with search term', async () => {
      const term = 'lorem';

      createComponent();

      findListbox().vm.$emit('search', term);
      await nextTick();

      expect(findListbox().props('loading')).toBe(true);

      await waitForPromises();

      expect(Api.projectProtectedBranches).toHaveBeenCalledWith(TEST_PROJECT_ID, term);
      expect(wrapper.emitted('apiError')).toStrictEqual([
        [{ hasErrored: false }],
        [{ hasErrored: false }],
      ]);
      expect(findListbox().props('loading')).toBe(false);
    });

    it('fetches protected branches with no all branches if there is a search', async () => {
      createComponent();

      findListbox().vm.$emit('search', 'main');
      await waitForPromises();

      expect(findSelectableBranches()).toStrictEqual(protectedBranchNames());
    });

    it('fetches protected branches with all branches if search contains term "all"', async () => {
      createComponent();

      findListbox().vm.$emit('search', 'all');
      await waitForPromises();

      expect(findSelectableBranches()).toStrictEqual(branchNames());
    });

    describe('with allow all protected branches option', () => {
      it('fetches protected branches with all branches if search contains term "all"', async () => {
        createComponent({ allowAllProtectedBranchesOption: true }, mount);

        findListbox().vm.$emit('search', 'all');
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
          findListbox().vm.$emit('search', 'all');

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
        createComponent();

        return waitForPromises();
      });

      it('emits the `apiError` event and returns no items when searching for a term', async () => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        findListbox().vm.$emit('search', 'main');

        await waitForPromises();

        expect(wrapper.emitted('apiError')).toStrictEqual([
          [{ hasErrored: false }],
          [{ hasErrored: true, error }],
        ]);
        expect(findListbox().props('items')).toHaveLength(0);
      });

      it('emits the `apiError` event and returns all branches when searching for "all"', async () => {
        jest.spyOn(Api, 'projectProtectedBranches').mockRejectedValueOnce(error);
        findListbox().vm.$emit('search', 'all');

        await waitForPromises();

        expect(wrapper.emitted('apiError')).toStrictEqual([
          [{ hasErrored: false }],
          [{ hasErrored: true, error }],
        ]);
        expect(findSelectableBranches()).toStrictEqual([ALL_BRANCHES.name]);
      });
    });
  });
});
