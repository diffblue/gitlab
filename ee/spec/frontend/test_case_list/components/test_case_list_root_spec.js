import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import TestCaseListRoot from 'ee/test_case_list/components/test_case_list_root.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { mockIssuable } from 'jest/vue_shared/issuable/list/mock_data';

import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';

jest.mock('~/flash');
jest.mock('ee/test_case_list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
  TestCaseTabs: jest.requireActual('ee/test_case_list/constants').TestCaseTabs,
  AvailableSortOptions: jest.requireActual('ee/test_case_list/constants').AvailableSortOptions,
}));

const mockProvide = {
  canCreateTestCase: true,
  initialState: 'opened',
  page: 1,
  prev: '',
  next: '',
  initialSortBy: 'created_desc',
  projectFullPath: 'gitlab-org/gitlab-test',
  projectLabelsPath: '/gitlab-org/gitlab-test/-/labels.json',
  testCaseNewPath: '/gitlab-org/gitlab-test/-/quality/test_cases/new',
};

const mockPageInfo = {
  startCursor: 'eyJpZCI6IjI1IiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzI6MTQgVVRDIn0',
  endCursor: 'eyJpZCI6IjIxIiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzE6MTUgVVRDIn0',
};

describe('TestCaseListRoot', () => {
  let wrapper;

  const getIssuableList = () => wrapper.findComponent(IssuableList);

  const createComponent = ({
    provide = mockProvide,
    initialFilterParams = {},
    testCasesLoading = false,
    data = {},
  } = {}) => {
    wrapper = shallowMount(TestCaseListRoot, {
      propsData: {
        initialFilterParams,
      },
      data() {
        return data;
      },
      provide,
      mocks: {
        $apollo: {
          queries: {
            project: {
              loading: testCasesLoading,
            },
          },
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('passes a correct loading state to Issuables List', () => {
    it.each`
      testCasesLoading | returnValue
      ${true}          | ${true}
      ${false}         | ${false}
    `(
      'passes $returnValue to Issuables List prop when query loading is $testCasesLoading',
      ({ testCasesLoading, returnValue }) => {
        createComponent({
          provide: mockProvide,
          initialFilterParams: {},
          testCasesList: [],
          testCasesLoading,
        });

        expect(getIssuableList().props('issuablesLoading')).toBe(returnValue);
      },
    );
  });

  describe('computed', () => {
    describe('showPaginationControls', () => {
      it.each`
        hasPreviousPage | hasNextPage  | returnValue
        ${true}         | ${undefined} | ${true}
        ${undefined}    | ${true}      | ${true}
        ${false}        | ${undefined} | ${false}
        ${undefined}    | ${false}     | ${false}
        ${false}        | ${false}     | ${false}
        ${true}         | ${true}      | ${true}
      `(
        'returns $returnValue when hasPreviousPage is $hasPreviousPage and hasNextPage is $hasNextPage within `testCases.pageInfo`',
        async ({ hasPreviousPage, hasNextPage, returnValue }) => {
          createComponent({
            data: {
              project: {
                issues: {
                  pageInfo: {
                    hasPreviousPage,
                    hasNextPage,
                  },
                },
              },
            },
          });

          expect(getIssuableList().props('showPaginationControls')).toBe(returnValue);
        },
      );

      it.each`
        testCasesList     | testCaseListDescription | returnValue
        ${[]}             | ${'empty'}              | ${false}
        ${[mockIssuable]} | ${'not empty'}          | ${true}
      `(
        'returns $returnValue when testCases array is $testCaseListDescription',
        async ({ testCasesList, returnValue }) => {
          createComponent({
            data: {
              project: {
                issues: {
                  nodes: testCasesList,
                },
              },
            },
          });

          expect(getIssuableList().props('showPaginationControls')).toBe(returnValue);
        },
      );
    });

    describe('previousPage', () => {
      it('returns number representing previous page based on currentPage value', () => {
        createComponent({
          data: {
            currentPage: 3,
          },
        });

        expect(getIssuableList().props('previousPage')).toBe(2);
      });
    });

    describe('nextPage', () => {
      beforeEach(() => {
        createComponent({
          data: {
            project: {
              issueStatusCounts: {
                opened: 5,
                closed: 0,
                all: 5,
              },
            },
          },
        });
      });

      it('returns number representing next page based on currentPage value', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentPage: 1,
        });

        await nextTick;

        expect(getIssuableList().props('nextPage')).toBe(2);
      });

      it('returns `null` when currentPage is already last page', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentPage: 3,
        });

        await nextTick;

        expect(getIssuableList().props('nextPage')).toBeNull();
      });
    });
  });

  describe('methods', () => {
    describe('updateUrl', () => {
      it('updates window URL based on presence of props for filtered search and sort criteria', async () => {
        createComponent({
          data: {
            currentState: 'opened',
            currentPage: 2,
            nextPageCursor: 'abc123',
            sortedBy: 'updated_asc',
            filterParams: {
              authorUsernames: 'root',
              search: 'foo',
              labelName: ['bug'],
            },
          },
        });

        wrapper.vm.updateUrl();

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?state=opened&sort=updated_asc&page=2&next=abc123&label_name%5B%5D=bug&search=foo`,
        );
      });
    });
  });

  describe('template', () => {
    describe('issuable-list events', () => {
      beforeEach(() => {
        createComponent();
        jest.spyOn(wrapper.vm, 'updateUrl').mockImplementation(jest.fn);
      });

      it('click-tab event changes currentState value and calls updateUrl', async () => {
        getIssuableList().vm.$emit('click-tab', 'closed');

        await nextTick;
        expect(getIssuableList().props('currentTab')).toBe('closed');
        expect(wrapper.vm.updateUrl).toHaveBeenCalled();
      });

      it('page-change event changes prevPageCursor and nextPageCursor values based on based on currentPage and calls updateUrl', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        await wrapper.setData({
          testCases: {
            pageInfo: mockPageInfo,
          },
        });

        getIssuableList().vm.$emit('page-change', 2);

        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe(mockPageInfo.endCursor);
        expect(wrapper.vm.updateUrl).toHaveBeenCalled();
      });

      it('filter event changes filterParams value and calls updateUrl', async () => {
        getIssuableList().vm.$emit('filter', [
          {
            type: 'author_username',
            value: {
              data: 'root',
            },
          },
          {
            type: 'label_name',
            value: {
              data: 'bug',
            },
          },
          {
            type: 'filtered-search-term',
            value: {
              data: 'foo',
            },
          },
        ]);

        await nextTick;

        expect(getIssuableList().props('initialFilterValue')).toEqual([
          { type: 'author_username', value: { data: 'root' } },
          { type: 'label_name', value: { data: 'bug' } },
          'foo',
        ]);
        expect(wrapper.vm.updateUrl).toHaveBeenCalled();
      });

      it('sort event changes sortedBy value and calls updateUrl', async () => {
        getIssuableList().vm.$emit('sort', 'updated_desc');

        await nextTick;

        expect(getIssuableList().props('initialSortBy')).toBe('updated_desc');
        expect(wrapper.vm.updateUrl).toHaveBeenCalled();
      });
    });
  });
});
