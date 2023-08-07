import { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import { GlCollapsibleListbox, GlLoadingIcon, GlListboxItem } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProtectedBranchesDropdown from 'ee/security_orchestration/components/policy_editor/protected_branches_dropdown.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';

const MOCKED_PROTECTED_BRANCHES = [
  { id: 1, name: 'main' },
  { id: 2, name: 'development' },
  { id: 3, name: 'test1' },
];

const MOCKED_LISTBOX_ITEMS = MOCKED_PROTECTED_BRANCHES.map(({ name }) => ({
  text: name,
  value: name,
}));

describe('ProtectedBranchesDropdown', () => {
  const PROJECT_ID = '1';
  const MOCKED_PROTECTED_BRANCHES_URL = `/api/v4/projects/${PROJECT_ID}/protected_branches`;

  let wrapper;
  const mockAxios = new MockAdapter(axios);

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ProtectedBranchesDropdown, {
      propsData: {
        projectId: PROJECT_ID,
        ...propsData,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  beforeEach(() => {
    gon.api_version = 'v4';
  });

  afterEach(() => {
    mockAxios.reset();
  });

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findToggleLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSelectAllButton = () => wrapper.findByTestId('listbox-select-all-button');
  const findEmptyState = () => wrapper.findByTestId('listbox-no-results-text');

  const openDropdown = async () => {
    findListBox().vm.$emit('shown');
    await waitForPromises();
  };

  describe('loading state', () => {
    beforeEach(() => {
      mockAxios
        .onGet(MOCKED_PROTECTED_BRANCHES_URL)
        .replyOnce(HTTP_STATUS_OK, MOCKED_PROTECTED_BRANCHES);
    });

    it('should not initially load branches', () => {
      createComponent();

      expect(findListBox().props('loading')).toBe(false);
      expect(findListBox().props('items')).toEqual([]);
    });

    it('should display loading icon on first load', async () => {
      createComponent();

      findListBox().vm.$emit('shown');
      await nextTick();

      expect(findListBox().props('loading')).toBe(true);
      expect(findToggleLoadingIcon().exists()).toBe(true);
    });
  });

  describe('loading successfully', () => {
    describe('has protected branches', () => {
      beforeEach(() => {
        mockAxios
          .onGet(MOCKED_PROTECTED_BRANCHES_URL)
          .replyOnce(HTTP_STATUS_OK, MOCKED_PROTECTED_BRANCHES);
      });

      it('should render branches in a dropdown', async () => {
        createComponent();

        await openDropdown();

        expect(findListBox().props('items')).toEqual(MOCKED_LISTBOX_ITEMS);
        expect(findAllListboxItems()).toHaveLength(MOCKED_LISTBOX_ITEMS.length);

        expect(wrapper.emitted('error')).toEqual([[{ hasErrored: false }]]);
        expect(findListBox().props('variant')).toEqual('default');
        expect(findListBox().props('category')).toEqual('primary');
      });

      it('should select all branches in multiple mode', async () => {
        createComponent();

        await openDropdown();

        findListBox().vm.$emit('select-all');

        expect(wrapper.emitted('input')).toEqual([
          [MOCKED_PROTECTED_BRANCHES.map(({ name }) => name)],
        ]);
      });

      it('should reset branches in multiple mode', async () => {
        createComponent({
          selected: [MOCKED_PROTECTED_BRANCHES.map(({ name }) => name)],
        });

        await openDropdown();

        findListBox().vm.$emit('reset');

        expect(wrapper.emitted('input')).toEqual([[[]]]);
      });

      it.each([true, false])(
        'should render select all button for multiple selection',
        async (multiple) => {
          createComponent({ propsData: { multiple } });

          await openDropdown();

          expect(findSelectAllButton().exists()).toBe(multiple);
        },
      );

      it.each`
        multiple | selected                   | expectedSelected           | expectedResult
        ${true}  | ${['main', 'development']} | ${['main', 'development']} | ${['main', 'development'].join(', ')}
        ${true}  | ${undefined}               | ${[]}                      | ${'Select protected branches'}
        ${false} | ${'main'}                  | ${'main'}                  | ${'main'}
        ${false} | ${null}                    | ${null}                    | ${'Select protected branch'}
        ${false} | ${[]}                      | ${[]}                      | ${'Select protected branch'}
      `(
        'should select saved previously saved branches',
        async ({ multiple, selected, expectedSelected, expectedResult }) => {
          createComponent({
            propsData: {
              selected,
              multiple,
            },
          });

          await openDropdown();

          expect(findListBox().props('selected')).toEqual(expectedSelected);
          expect(findListBox().props('toggleText')).toBe(expectedResult);
        },
      );
    });

    describe('has no protected branches', () => {
      beforeEach(() => {
        mockAxios.onGet(MOCKED_PROTECTED_BRANCHES_URL).replyOnce(HTTP_STATUS_OK, []);
      });

      it('should render empty state if no branches exist', async () => {
        createComponent();

        await openDropdown();

        expect(findAllListboxItems()).toHaveLength(0);
        expect(findEmptyState().text()).toBe('No results found');
      });
    });
  });

  describe('loading failed', () => {
    beforeEach(() => {
      mockAxios.onGet(MOCKED_PROTECTED_BRANCHES_URL).replyOnce(HTTP_STATUS_BAD_REQUEST);
    });

    it('should emmit error when loading fails', async () => {
      const sentrySpy = jest.spyOn(Sentry, 'captureException');

      createComponent();

      await openDropdown();

      expect(wrapper.emitted('error')).toHaveLength(1);
      expect(findAllListboxItems()).toHaveLength(0);
      expect(findEmptyState().text()).toBe('No results found');
      expect(sentrySpy).toHaveBeenCalledWith(new Error('Request failed with status code 400'));
    });

    it.each`
      errorMessage              | expectedError
      ${undefined}              | ${'Could not retrieve the list of protected branches. Use the YAML editor mode, or refresh this page later. To view the list of protected branches, go to %{boldStart}Settings - Branches%{boldEnd} and expand %{boldStart}Protected branches%{boldEnd}.'}
      ${'custom error message'} | ${'custom error message'}
    `(
      'should have error class when hasError and accept custom error message',
      async ({ errorMessage, expectedError }) => {
        createComponent({
          propsData: {
            hasError: true,
            errorMessage,
          },
        });

        await openDropdown();

        expect(wrapper.emitted('error')).toEqual([
          [
            {
              error: expectedError,
              hasErrored: true,
            },
          ],
        ]);

        expect(findListBox().props('variant')).toEqual('danger');
        expect(findListBox().props('category')).toEqual('secondary');
      },
    );
  });
});
