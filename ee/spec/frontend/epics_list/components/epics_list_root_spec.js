import { shallowMount } from '@vue/test-utils';
import { pick } from 'lodash';

import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import EpicsListRoot from 'ee/epics_list/components/epics_list_root.vue';
import { epicsSortOptions } from 'ee/epics_list/constants';
import groupEpicsQuery from 'ee/epics_list//queries/group_epics.query.graphql';
import { mockFormattedEpic } from 'ee_jest/roadmap/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { mockAuthor, mockLabels } from 'jest/vue_shared/issuable/list/mock_data';

import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
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
    nodes: mockLabels,
  },
  startDate: '2021-04-01',
  dueDate: '2021-06-30',
  createdAt: '2021-04-01',
  updatedAt: '2021-05-01',
  blockingCount: 0,
  upvotes: 0,
  downvotes: 0,
  group: null,
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

const groupEpicsQueryHandler = jest.fn().mockResolvedValue({
  data: {
    group: {
      epics: {
        nodes: mockEpics,
        pageInfo: mockPageInfo,
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

const createComponent = ({ provide = mockProvide, initialFilterParams = {} } = {}) => {
  mockApollo = createMockApollo(
    [[groupEpicsQuery, groupEpicsQueryHandler]],
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
  wrapper = shallowMount(EpicsListRoot, {
    propsData: {
      initialFilterParams,
    },
    apolloProvider: mockApollo,
    provide,
    stubs: {
      IssuableList: stubComponent(IssuableList),
    },
  });
};

describe('EpicsListRoot', () => {
  const getIssuableList = () => wrapper.findComponent(IssuableList);

  describe('methods', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('epicReference', () => {
      const mockEpicWithPath = {
        ...mockFormattedEpic,
        group: {
          fullPath: 'gitlab-org/marketing',
        },
      };
      const mockEpicWithoutPath = {
        ...mockFormattedEpic,
        group: {
          fullPath: 'gitlab-org',
        },
      };

      it.each`
        epic                   | reference
        ${mockEpicWithPath}    | ${'gitlab-org/marketing&2'}
        ${mockEpicWithoutPath} | ${'&2'}
      `(
        'returns string "$reference" based on provided `epic.group.fullPath`',
        ({ epic, reference }) => {
          expect(wrapper.vm.epicReference(epic)).toBe(reference);
        },
      );
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
        ({ startDate, dueDate, returnValue }) => {
          expect(
            wrapper.vm.epicTimeframe({
              startDate,
              dueDate,
            }),
          ).toBe(returnValue);
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
      await nextTick();

      expect(groupEpicsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          prevPageCursor: mockPageInfo.startCursor,
          nextPageCursor: '',
          lastPageSize: 2,
        }),
      );

      getIssuableList().vm.$emit('page-change', 2);

      await waitForPromises();
      await nextTick();

      expect(groupEpicsQueryHandler).toHaveBeenCalledWith(
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
      await nextTick();

      expect(groupEpicsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          prevPageCursor: mockPageInfo.startCursor,
          nextPageCursor: '',
        }),
      );

      getIssuableList().vm.$emit('sort', 'TITLE_DESC');

      await waitForPromises();
      await nextTick();

      expect(groupEpicsQueryHandler).toHaveBeenCalledWith(
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
      jest.spyOn(wrapper.vm, 'getFilteredSearchTokens');

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
        urlParams: wrapper.vm.urlParams,
        issuableSymbol: '&',
        recentSearchesStorageKey: 'epics',
      });

      expect(wrapper.vm.getFilteredSearchTokens).toHaveBeenCalledWith({
        supportsEpic: false,
      });
    });

    it.each`
      hasPreviousPage | hasNextPage  | returnValue
      ${true}         | ${undefined} | ${true}
      ${undefined}    | ${true}      | ${true}
      ${false}        | ${undefined} | ${false}
      ${undefined}    | ${false}     | ${false}
      ${false}        | ${false}     | ${false}
      ${true}         | ${true}      | ${true}
    `(
      'sets showPaginationControls prop value as $returnValue when hasPreviousPage is $hasPreviousPage and hasNextPage is $hasNextPage within `epics.pageInfo`',
      async ({ hasPreviousPage, hasNextPage, returnValue }) => {
        createComponent();
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          epics: {
            pageInfo: {
              hasPreviousPage,
              hasNextPage,
            },
          },
        });

        await nextTick();

        expect(getIssuableList().props('showPaginationControls')).toBe(returnValue);
      },
    );

    it('sets previousPage prop value a number representing previous page based on currentPage value', async () => {
      createComponent();
      getIssuableList().vm.$emit('page-change', 3);

      await nextTick();

      expect(wrapper.vm.previousPage).toBe(2);
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
