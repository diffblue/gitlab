import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectBranchSelector from 'ee/vue_shared/components/branches_selector/project_branch_selector.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

const branches = Array.from({ length: 15 }, (_, index) => ({ id: index, name: `test-${index}` }));
const TEST_BRANCHES = [{ id: 16, name: 'main' }, ...branches];

const MOCKED_LISTBOX_ITEMS = TEST_BRANCHES.map(({ name }) => ({
  text: name,
  value: name,
}));

const TOTAL_BRANCHES = 30;

describe('ProjectBranchSelector', () => {
  const PROJECT_ID = '1';
  const MOCKED_BRANCHES_URL = `/api/v4/projects/${PROJECT_ID}/repository/branches`;

  let wrapper;
  const mockAxios = new MockAdapter(axios);

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ProjectBranchSelector, {
      propsData: {
        projectFullPath: PROJECT_ID,
        ...propsData,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findEmptyState = () => wrapper.findByTestId('listbox-no-results-text');

  beforeEach(() => {
    gon.api_version = 'v4';
  });

  afterEach(() => {
    mockAxios.reset();
  });

  const openDropdown = async () => {
    findListBox().vm.$emit('shown');
    await waitForPromises();
  };

  it('should render custom header and text', () => {
    const customHeader = 'custom header';
    const customText = 'custom text';

    createComponent({
      propsData: {
        header: customHeader,
        text: customText,
      },
    });

    expect(findListBox().props('headerText')).toBe(customHeader);
    expect(findListBox().props('toggleText')).toBe(customText);
  });

  describe('loading state', () => {
    beforeEach(() => {
      mockAxios.onGet(MOCKED_BRANCHES_URL).replyOnce(HTTP_STATUS_OK, TEST_BRANCHES, {
        'x-total': TOTAL_BRANCHES,
      });
    });

    it('should not initially load branches', () => {
      createComponent();

      expect(findListBox().props('loading')).toBe(false);
      expect(findListBox().props('items')).toEqual([]);
    });

    it('should have loading state on first load', async () => {
      createComponent();

      findListBox().vm.$emit('shown');
      await nextTick();

      expect(findListBox().props('loading')).toBe(true);
    });
  });

  describe('loading successfully', () => {
    beforeEach(() => {
      mockAxios.onGet(MOCKED_BRANCHES_URL).reply(HTTP_STATUS_OK, TEST_BRANCHES, {
        'x-total': TOTAL_BRANCHES,
      });
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

      expect(wrapper.emitted('select')).toEqual([[MOCKED_LISTBOX_ITEMS.map(({ value }) => value)]]);
    });

    it('should reset branches in multiple mode', async () => {
      createComponent({
        propsData: {
          selected: MOCKED_LISTBOX_ITEMS.map(({ value }) => value),
        },
      });

      await openDropdown();

      findListBox().vm.$emit('reset');

      expect(wrapper.emitted('select')).toEqual([[[]]]);
    });

    it('should stop fetching branches when limit is reached', async () => {
      createComponent();
      await openDropdown();

      expect(findListBox().props('items')).toHaveLength(TEST_BRANCHES.length);

      findListBox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(findListBox().props('items')).toHaveLength(TEST_BRANCHES.length);
    });

    it.each`
      selected                   | expectedSelected           | expectedResult
      ${['main', 'development']} | ${['main', 'development']} | ${['main', 'development'].join(', ')}
      ${undefined}               | ${[]}                      | ${'Select branches'}
    `(
      'should select saved previously saved branches',
      async ({ selected, expectedSelected, expectedResult }) => {
        createComponent({
          propsData: {
            selected,
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
      mockAxios.onGet(MOCKED_BRANCHES_URL).replyOnce(HTTP_STATUS_OK, []);
    });

    it('should render empty state if no branches exist', async () => {
      createComponent();

      await openDropdown();

      expect(findAllListboxItems()).toHaveLength(0);
      expect(findEmptyState().text()).toBe('No results found');
    });
  });

  describe('loading failed', () => {
    beforeEach(() => {
      mockAxios.onGet(MOCKED_BRANCHES_URL).replyOnce(HTTP_STATUS_BAD_REQUEST);
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
      ${undefined}              | ${'Could not retrieve the list of branches. Use the YAML editor mode, or refresh this page later. To view the list of branches, go to %{boldStart}Code - Branches%{boldEnd}'}
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
