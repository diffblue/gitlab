import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';

import TestCaseListRoot from 'ee/test_case_list/components/test_case_list_root.vue';
import projectTestCases from 'ee/test_case_list/queries/project_test_cases.query.graphql';
import { TEST_HOST } from 'helpers/test_constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockIssuableItems } from 'jest/vue_shared/issuable/list/mock_data';

import {
  FILTERED_SEARCH_TERM,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';

jest.mock('~/vue_shared/issuable/list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
}));

const mockProvide = {
  canCreateTestCase: true,
  hasScopedLabelsFeature: true,
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
  hasNextPage: true,
  hasPreviousPage: false,
  startCursor: 'eyJpZCI6IjI1IiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzI6MTQgVVRDIn0',
  endCursor: 'eyJpZCI6IjIxIiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzE6MTUgVVRDIn0',
};

describe('TestCaseListRoot', () => {
  let wrapper;

  const defaultHandlers = ({ nodes = mockIssuableItems(10), pagination = {} } = {}) =>
    jest.fn().mockResolvedValue({
      data: {
        project: {
          id: 'id',
          name: 'name',
          issueStatusCounts: {
            opened: 5,
            closed: 0,
            all: 5,
          },
          issues: {
            nodes,
            pageInfo: {
              __typename: 'PageInfo',
              ...mockPageInfo,
              ...pagination,
            },
          },
        },
      },
    });

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    return createMockApollo([[projectTestCases, handlers]]);
  };

  const findIssuableList = () => wrapper.findComponent(IssuableList);

  const createComponent = ({
    provide = mockProvide,
    initialFilterParams = {},
    handlers = defaultHandlers(),
  } = {}) => {
    wrapper = shallowMount(TestCaseListRoot, {
      propsData: {
        initialFilterParams,
      },
      provide,
      apolloProvider: createMockApolloProvider(handlers),
    });
  };

  describe('passes a correct loading state to Issuables List', () => {
    it.each`
      testCasesLoading | returnValue
      ${true}          | ${true}
      ${false}         | ${false}
    `(
      'passes $returnValue to Issuables List prop when query loading is $testCasesLoading',
      async ({ testCasesLoading, returnValue }) => {
        createComponent({
          provide: mockProvide,
          initialFilterParams: {},
          testCasesList: [],
        });

        if (!testCasesLoading) {
          await waitForPromises();
        }

        expect(findIssuableList().props('issuablesLoading')).toBe(returnValue);
      },
    );
  });

  describe('computed', () => {
    describe('showPaginationControls', () => {
      it.each`
        hasPreviousPage | hasNextPage | returnValue
        ${true}         | ${false}    | ${true}
        ${false}        | ${true}     | ${true}
        ${false}        | ${false}    | ${false}
        ${true}         | ${true}     | ${true}
      `(
        'returns $returnValue when hasPreviousPage is $hasPreviousPage and hasNextPage is $hasNextPage within `testCases.pageInfo`',
        async ({ hasPreviousPage, hasNextPage, returnValue }) => {
          createComponent({
            handlers: defaultHandlers({
              nodes: mockIssuableItems(10),
              pagination: {
                hasPreviousPage,
                hasNextPage,
              },
            }),
          });

          await waitForPromises();

          expect(findIssuableList().props('showPaginationControls')).toBe(returnValue);
        },
      );

      it.each`
        testCasesList           | testCaseListDescription | returnValue
        ${[]}                   | ${'empty'}              | ${false}
        ${mockIssuableItems(5)} | ${'not empty'}          | ${true}
      `(
        'returns $returnValue when testCases array is $testCaseListDescription',
        async ({ testCasesList, returnValue }) => {
          createComponent({
            handlers: defaultHandlers({
              nodes: testCasesList,
              pagination: {
                hasPreviousPage: returnValue,
                hasNextPage: returnValue,
              },
            }),
          });

          await waitForPromises();

          expect(findIssuableList().props('showPaginationControls')).toBe(returnValue);
        },
      );
    });

    describe('previousPage', () => {
      it('returns number representing previous page based on currentPage value', async () => {
        createComponent();
        await findIssuableList().vm.$emit('page-change', 3);

        expect(findIssuableList().props('previousPage')).toBe(2);
      });
    });

    describe('nextPage', () => {
      beforeEach(() => {
        createComponent();
      });

      it('returns number representing next page based on currentPage value', async () => {
        await findIssuableList().vm.$emit('page-change', 1);

        expect(findIssuableList().props('nextPage')).toBe(2);
      });

      it('returns `null` when currentPage is already last page', async () => {
        await findIssuableList().vm.$emit('page-change', 3);

        expect(findIssuableList().props('nextPage')).toBeNull();
      });
    });
  });

  describe('methods', () => {
    describe('updateUrl', () => {
      it('updates window URL based on presence of props for filtered search and sort criteria', async () => {
        createComponent();

        await findIssuableList().vm.$emit('click-tab', 'tab');

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?state=tab&sort=created_desc&page=1`,
        );
      });
    });
  });

  describe('template', () => {
    describe('issuable-list events', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('click-tab event changes currentState value and calls updateUrl', async () => {
        await findIssuableList().vm.$emit('click-tab', 'closed');
        expect(findIssuableList().props('currentTab')).toBe('closed');
      });

      it('page-change event changes prevPageCursor and nextPageCursor values based on based on currentPage', () => {
        findIssuableList().vm.$emit('page-change', 2);

        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe(mockPageInfo.endCursor);
      });

      it('filter event changes filterParams value', async () => {
        await findIssuableList().vm.$emit('filter', [
          {
            type: TOKEN_TYPE_AUTHOR,
            value: {
              data: 'root',
            },
          },
          {
            type: TOKEN_TYPE_LABEL,
            value: {
              data: 'bug',
            },
          },
          {
            type: FILTERED_SEARCH_TERM,
            value: {
              data: 'foo',
            },
          },
        ]);

        expect(findIssuableList().props('initialFilterValue')).toEqual([
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'root' } },
          { type: TOKEN_TYPE_LABEL, value: { data: 'bug' } },
          'foo',
        ]);
      });

      it('sort event changes sortedBy value', async () => {
        await findIssuableList().vm.$emit('sort', 'updated_desc');

        expect(findIssuableList().props('initialSortBy')).toBe('updated_desc');
      });
    });
  });
});
