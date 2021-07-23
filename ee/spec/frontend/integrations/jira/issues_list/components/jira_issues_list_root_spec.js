import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';

import JiraIssuesListRoot from 'ee/integrations/jira/issues_list/components/jira_issues_list_root.vue';
import { ISSUES_LIST_FETCH_ERROR } from 'ee/integrations/jira/issues_list/constants';
import jiraIssues from 'ee/integrations/jira/issues_list/graphql/resolvers/jira_issues';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import createFlash from '~/flash';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

import { mockProvide, mockJiraIssues } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/issuable_list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
  IssuableStates: jest.requireActual('~/issuable_list/constants').IssuableStates,
  IssuableListTabs: jest.requireActual('~/issuable_list/constants').IssuableListTabs,
  AvailableSortOptions: jest.requireActual('~/issuable_list/constants').AvailableSortOptions,
}));
jest.mock(
  '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue',
  () => 'LabelTokenMock',
);

const resolvedValue = {
  headers: {
    'x-page': 1,
    'x-total': mockJiraIssues.length,
  },
  data: mockJiraIssues,
};

const localVue = createLocalVue();

const resolvers = {
  Query: {
    jiraIssues,
  },
};

function createMockApolloProvider(mockResolvers = resolvers) {
  localVue.use(VueApollo);
  return createMockApollo([], mockResolvers);
}

describe('JiraIssuesListRoot', () => {
  let wrapper;
  let mock;

  const mockSearchTerm = 'test issue';
  const mockLabel = 'ecosystem';

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const createLabelFilterEvent = (data) => ({ type: 'labels', value: { data } });
  const createSearchFilterEvent = (data) => ({ type: 'filtered-search-term', value: { data } });

  const createComponent = ({
    apolloProvider = createMockApolloProvider(),
    provide = mockProvide,
    initialFilterParams = {},
  } = {}) => {
    wrapper = shallowMount(JiraIssuesListRoot, {
      propsData: {
        initialFilterParams,
      },
      provide,
      localVue,
      apolloProvider,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('while loading', () => {
    it('sets issuesListLoading to `true`', async () => {
      jest.spyOn(axios, 'get').mockResolvedValue(new Promise(() => {}));

      createComponent();
      await wrapper.vm.$nextTick();

      const issuableList = findIssuableList();
      expect(issuableList.props('issuablesLoading')).toBe(true);
    });

    it('calls `axios.get` with `issuesFetchPath` and query params', async () => {
      jest.spyOn(axios, 'get');

      createComponent();
      await waitForPromises();

      expect(axios.get).toHaveBeenCalledWith(
        mockProvide.issuesFetchPath,
        expect.objectContaining({
          params: {
            with_labels_details: true,
            page: wrapper.vm.currentPage,
            per_page: wrapper.vm.$options.defaultPageSize,
            state: wrapper.vm.currentState,
            sort: wrapper.vm.sortedBy,
            search: wrapper.vm.filterParams.search,
          },
        }),
      );
    });
  });

  describe('with `initialFilterParams` prop', () => {
    beforeEach(async () => {
      jest.spyOn(axios, 'get').mockResolvedValue(resolvedValue);

      createComponent({
        initialFilterParams: {
          labels: [mockLabel],
          search: mockSearchTerm,
        },
      });
      await waitForPromises();
    });

    it('renders issuable-list component with correct props', () => {
      const issuableList = findIssuableList();

      expect(issuableList.props('initialFilterValue')).toEqual([
        { type: 'labels', value: { data: mockLabel } },
        { type: 'filtered-search-term', value: { data: mockSearchTerm } },
      ]);
      expect(issuableList.props('urlParams').search).toBe(mockSearchTerm);
    });
  });

  describe('when request succeeds', () => {
    beforeEach(async () => {
      jest.spyOn(axios, 'get').mockResolvedValue(resolvedValue);

      createComponent();
      await waitForPromises();
    });

    it('renders issuable-list component with correct props', () => {
      const issuableList = findIssuableList();
      expect(issuableList.exists()).toBe(true);
      expect(issuableList.props()).toMatchSnapshot();
    });

    describe('issuable-list events', () => {
      it('"click-tab" event executes GET request correctly', async () => {
        const issuableList = findIssuableList();

        issuableList.vm.$emit('click-tab', 'closed');
        await waitForPromises();

        expect(axios.get).toHaveBeenCalledWith(mockProvide.issuesFetchPath, {
          params: {
            labels: undefined,
            page: 1,
            per_page: 2,
            search: undefined,
            sort: 'created_desc',
            state: 'closed',
            with_labels_details: true,
          },
        });
        expect(issuableList.props('currentTab')).toBe('closed');
      });

      it('"page-change" event executes GET request correctly', async () => {
        const mockPage = 2;
        const issuableList = findIssuableList();
        jest.spyOn(axios, 'get').mockResolvedValue({
          ...resolvedValue,
          headers: { 'x-page': mockPage, 'x-total': mockJiraIssues.length },
        });

        issuableList.vm.$emit('page-change', mockPage);
        await waitForPromises();

        expect(axios.get).toHaveBeenCalledWith(mockProvide.issuesFetchPath, {
          params: {
            labels: undefined,
            page: mockPage,
            per_page: 2,
            search: undefined,
            sort: 'created_desc',
            state: 'opened',
            with_labels_details: true,
          },
        });

        await wrapper.vm.$nextTick();
        expect(issuableList.props()).toMatchObject({
          currentPage: mockPage,
          previousPage: mockPage - 1,
          nextPage: mockPage + 1,
        });
      });

      it('"sort" event executes GET request correctly', async () => {
        const mockSortBy = 'updated_asc';
        const issuableList = findIssuableList();

        issuableList.vm.$emit('sort', mockSortBy);
        await waitForPromises();

        expect(axios.get).toHaveBeenCalledWith(mockProvide.issuesFetchPath, {
          params: {
            labels: undefined,
            page: 1,
            per_page: 2,
            search: undefined,
            sort: 'created_desc',
            state: 'opened',
            with_labels_details: true,
          },
        });
        expect(issuableList.props('initialSortBy')).toBe(mockSortBy);
      });

      it.each`
        desc                        | input                                                                           | expected
        ${'with label and search'}  | ${[createLabelFilterEvent(mockLabel), createSearchFilterEvent(mockSearchTerm)]} | ${{ labels: [mockLabel], search: mockSearchTerm }}
        ${'with multiple lables'}   | ${[createLabelFilterEvent('label1'), createLabelFilterEvent('label2')]}         | ${{ labels: ['label1', 'label2'], search: undefined }}
        ${'with multiple searches'} | ${[createSearchFilterEvent('foo bar'), createSearchFilterEvent('lorem')]}       | ${{ labels: undefined, search: 'foo bar lorem' }}
      `(
        '$desc, filter event sets "filterParams" value and calls fetchIssues',
        async ({ input, expected }) => {
          const issuableList = findIssuableList();

          issuableList.vm.$emit('filter', input);
          await waitForPromises();

          expect(axios.get).toHaveBeenCalledWith(mockProvide.issuesFetchPath, {
            params: {
              page: 1,
              per_page: 2,
              sort: 'created_desc',
              state: 'opened',
              with_labels_details: true,
              ...expected,
            },
          });
        },
      );
    });
  });

  describe('error handling', () => {
    describe('when request fails', () => {
      it.each`
        APIErrors        | expectedRenderedErrorMessage
        ${['API error']} | ${'API error'}
        ${undefined}     | ${ISSUES_LIST_FETCH_ERROR}
      `(
        'calls `createFlash` with "$expectedRenderedErrorMessage" when API responds with "$APIErrors"',
        async ({ APIErrors, expectedRenderedErrorMessage }) => {
          jest.spyOn(axios, 'get');
          mock
            .onGet(mockProvide.issuesFetchPath)
            .replyOnce(httpStatus.INTERNAL_SERVER_ERROR, { errors: APIErrors });

          createComponent();
          await waitForPromises();

          expect(createFlash).toHaveBeenCalledWith({
            message: expectedRenderedErrorMessage,
            captureError: true,
            error: expect.any(Object),
          });
        },
      );
    });

    describe('when GraphQL network error is encountered', () => {
      it('calls `createFlash` correctly with default error message', async () => {
        createComponent({
          apolloProvider: createMockApolloProvider({
            Query: {
              jiraIssues: jest.fn().mockRejectedValue(new Error('GraphQL networkError')),
            },
          }),
        });
        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({
          message: ISSUES_LIST_FETCH_ERROR,
          captureError: true,
          error: expect.any(Object),
        });
      });
    });
  });

  describe('pagination', () => {
    it.each`
      scenario                 | issuesListLoadFailed | issues            | shouldShowPaginationControls
      ${'fails'}               | ${true}              | ${[]}             | ${false}
      ${'returns no issues'}   | ${false}             | ${[]}             | ${false}
      ${`returns some issues`} | ${false}             | ${mockJiraIssues} | ${true}
    `(
      'sets `showPaginationControls` prop to $shouldShowPaginationControls when request $scenario',
      async ({ issuesListLoadFailed, issues, shouldShowPaginationControls }) => {
        jest.spyOn(axios, 'get');
        mock
          .onGet(mockProvide.issuesFetchPath)
          .replyOnce(
            issuesListLoadFailed ? httpStatus.INTERNAL_SERVER_ERROR : httpStatus.OK,
            issues,
            {
              'x-page': 1,
              'x-total': issues.length,
            },
          );

        createComponent();
        await waitForPromises();

        expect(findIssuableList().props('showPaginationControls')).toBe(
          shouldShowPaginationControls,
        );
      },
    );
  });
});
