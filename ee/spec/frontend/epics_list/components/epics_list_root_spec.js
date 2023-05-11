import { pick } from 'lodash';

import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import EpicsListRoot from 'ee/epics_list/components/epics_list_root.vue';
import { epicsSortOptions } from 'ee/epics_list/constants';
import groupEpicsQuery from 'ee/epics_list//queries/group_epics.query.graphql';
import { mockFormattedEpic } from 'ee_jest/roadmap/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockAuthor, mockLabels } from 'jest/vue_shared/issuable/list/mock_data';

import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import IssuableItem from '~/vue_shared/issuable/list/components/issuable_item.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';

Vue.use(VueApollo);

jest.mock('~/vue_shared/issuable/list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
  issuableListTabs: jest.requireActual('~/vue_shared/issuable/list/constants').issuableListTabs,
  availableSortOptions: jest.requireActual('~/vue_shared/issuable/list/constants')
    .availableSortOptions,
}));

const mockRawEpic = {
  ...pick(mockFormattedEpic, ['title', 'webUrl', 'userDiscussionsCount', 'confidential']),
  author: mockAuthor,
  labels: {
    nodes: [...mockLabels.map((label) => ({ ...label, color: '#D9C2EE', __typename: 'Label' }))],
  },
  startDate: '2021-04-01',
  dueDate: '2021-06-30',
  createdAt: '2021-04-01',
  updatedAt: '2021-05-01',
  blockingCount: 0,
  upvotes: 0,
  downvotes: 0,
  group: {
    id: 'id',
    fullPath: 'gitlab-org/marketing',
  },
};

const mockEpics = new Array(5)
  .fill()
  .map((_, i) => ({ ...mockRawEpic, id: i + 1, iid: (i + 1) * 10 }));

const mockProvide = {
  canCreateEpic: true,
  canBulkEditEpics: true,
  hasScopedLabelsFeature: true,
  page: 1,
  prev: '',
  next: '',
  initialState: 'opened',
  initialSortBy: 'created_desc',
  epicNewPath: '/groups/gitlab-org/-/epics/new',
  groupFullPath: 'gitlab-org',
  groupLabelsPath: '/gitlab-org/-/labels.json',
  groupMilestonesPath: '/gitlab-org/-/milestone.json',
  listEpicsPath: '/gitlab-org/-/epics',
  emptyStatePath: '/assets/illustrations/empty-state/epics.svg',
  isSignedIn: false,
};

const mockPageInfo = {
  startCursor: 'eyJpZCI6IjI1IiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzI6MTQgVVRDIn0',
  endCursor: 'eyJpZCI6IjIxIiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzE6MTUgVVRDIn0',
};

let wrapper;
let mockApollo;
let requestHandler;

const groupEpicsQueryHandler = ({ nodes = mockEpics, pageInfo = mockPageInfo } = {}) =>
  jest.fn().mockResolvedValue({
    data: {
      group: {
        epics: {
          nodes,
          pageInfo,
        },
        totalEpics: {
          count: 5,
        },
        totalOpenedEpics: {
          count: 5,
        },
        totalClosedEpics: {
          count: 0,
        },
        id: 'gid://gitlab/Group/1',
      },
    },
  });

const createComponent = ({
  provide = mockProvide,
  initialFilterParams = {},
  handler = groupEpicsQueryHandler(),
} = {}) => {
  requestHandler = handler;

  mockApollo = createMockApollo(
    [[groupEpicsQuery, handler]],
    {},
    {
      typePolicies: {
        Query: {
          fields: {
            group: {
              merge: true,
            },
          },
        },
      },
    },
  );
  wrapper = shallowMountExtended(EpicsListRoot, {
    propsData: {
      initialFilterParams,
    },
    apolloProvider: mockApollo,
    provide,
    stubs: {
      IssuableList,
      IssuableItem,
    },
  });
};

describe('EpicsListRoot', () => {
  const getIssuableList = () => wrapper.findComponent(IssuableList);
  const findAllIssuableReference = () => wrapper.findAllByTestId('issuable-reference');

  describe('methods', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('epicReference', () => {
      it('renders Epic Reference based provided `epic.group.fullPath`', async () => {
        await waitForPromises();
        mockEpics.forEach((epic, index) => {
          expect(findAllIssuableReference().at(index).text()).toBe(
            `${epic.group.fullPath}&${epic.iid}`,
          );
        });
      });
    });

    describe('epicTimeframe', () => {
      it.each`
        startDate     | dueDate        | returnValue
        ${'2021-1-1'} | ${'2021-2-28'} | ${'Jan 1 – Feb 28, 2021'}
        ${'2021-1-1'} | ${'2022-2-28'} | ${'Jan 1, 2021 – Feb 28, 2022'}
        ${'2021-1-1'} | ${null}        | ${'Jan 1, 2021 – No due date'}
        ${null}       | ${'2021-2-28'} | ${'No start date – Feb 28, 2021'}
      `(
        'returns string "$returnValue" when startDate is $startDate and dueDate is $dueDate',
        async ({ startDate, dueDate, returnValue }) => {
          createComponent({
            handler: groupEpicsQueryHandler({
              nodes: [
                { ...mockRawEpic, startDate, dueDate, id: 1, iid: 10 },
                ...mockEpics.slice(1),
              ],
            }),
          });

          await waitForPromises();
          expect(wrapper.findByText(returnValue).exists()).toBe(true);
        },
      );
    });
  });

  describe('fetchEpicsBy', () => {
    it('updates prevPageCursor and nextPageCursor values when provided propsName param is "currentPage"', async () => {
      createComponent({
        provide: {
          ...mockProvide,
          prev: mockPageInfo.startCursor,
          next: mockPageInfo.endCursor,
        },
      });

      await waitForPromises();

      expect(requestHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          prevPageCursor: mockPageInfo.startCursor,
          nextPageCursor: '',
          lastPageSize: 2,
        }),
      );

      getIssuableList().vm.$emit('page-change', 2);

      await waitForPromises();

      expect(requestHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          prevPageCursor: '',
          nextPageCursor: '',
          firstPageSize: 2,
        }),
      );
    });

    it('updates prevPageCursor and nextPageCursor values when provided propsName param is "sortedBy"', async () => {
      createComponent({
        provide: {
          ...mockProvide,
          page: 2,
          prev: mockPageInfo.startCursor,
          next: mockPageInfo.endCursor,
        },
      });

      await waitForPromises();

      expect(requestHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          prevPageCursor: mockPageInfo.startCursor,
          nextPageCursor: '',
        }),
      );

      getIssuableList().vm.$emit('sort', 'TITLE_DESC');

      await waitForPromises();

      expect(requestHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          prevPageCursor: '',
          nextPageCursor: '',
        }),
      );
    });
  });

  describe('template', () => {
    it('renders issuable-list component', async () => {
      createComponent();
      await waitForPromises();

      getIssuableList().vm.$emit('filter', [
        { id: 'token-1', type: FILTERED_SEARCH_TERM, value: { data: 'foo' } },
      ]);

      await nextTick();

      expect(getIssuableList().exists()).toBe(true);
      expect(getIssuableList().props()).toMatchObject({
        namespace: mockProvide.groupFullPath,
        tabs: issuableListTabs,
        currentTab: 'opened',
        tabCounts: {
          all: 5,
          closed: 0,
          opened: 5,
        },
        searchInputPlaceholder: 'Search or filter results...',
        sortOptions: epicsSortOptions,
        initialFilterValue: ['foo'],
        initialSortBy: 'created_desc',
        urlParams: {
          author_username: undefined,
          confidential: undefined,
          epic_iid: undefined,
          group_path: undefined,
          in: undefined,
          'label_name[]': undefined,
          layout: undefined,
          milestone_title: undefined,
          milestones_type: undefined,
          my_reaction_emoji: undefined,
          next: undefined,
          'not[author_username]': undefined,
          'not[label_name][]': undefined,
          'not[my_reaction_emoji]': undefined,
          'or[author_username]': undefined,
          'or[label_name][]': undefined,
          page: 1,
          prev: undefined,
          progress: undefined,
          search: 'foo',
          show_labels: undefined,
          show_milestones: undefined,
          show_progress: undefined,
          sort: 'created_desc',
          state: 'opened',
          timeframe_range_type: undefined,
        },
        issuableSymbol: '&',
        recentSearchesStorageKey: 'epics',
      });
    });

    it.each`
      hasPreviousPage | hasNextPage | returnValue
      ${true}         | ${false}    | ${true}
      ${false}        | ${true}     | ${true}
      ${false}        | ${false}    | ${false}
      ${false}        | ${false}    | ${false}
      ${false}        | ${false}    | ${false}
      ${true}         | ${true}     | ${true}
    `(
      'sets showPaginationControls prop value as $returnValue when hasPreviousPage is $hasPreviousPage and hasNextPage is $hasNextPage within `epics.pageInfo`',
      async ({ hasPreviousPage, hasNextPage, returnValue }) => {
        createComponent({
          handler: groupEpicsQueryHandler({
            pageInfo: {
              ...mockPageInfo,
              hasPreviousPage,
              hasNextPage,
              __typename: 'PageInfo',
            },
          }),
        });

        await waitForPromises();
        expect(getIssuableList().props('showPaginationControls')).toBe(returnValue);
      },
    );

    it('sets previousPage prop value a number representing previous page based on currentPage value', async () => {
      createComponent();
      getIssuableList().vm.$emit('page-change', 3);

      await nextTick();

      expect(getIssuableList().props('previousPage')).toBe(2);
    });

    it('sets nextPage prop value a number representing next page based on currentPage value', async () => {
      createComponent({
        provide: {
          ...mockProvide,
          page: 2,
        },
      });

      await nextTick();

      expect(getIssuableList().props('nextPage')).toBe(3);
    });

    it('sets nextPage prop value as `null` when currentPage is already last page', async () => {
      createComponent({
        provide: {
          ...mockProvide,
          page: 3,
        },
      });

      await waitForPromises();

      expect(getIssuableList().props('nextPage')).toBeNull();
    });
  });
});
