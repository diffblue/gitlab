import { shallowMount } from '@vue/test-utils';
import { pick } from 'lodash';

import EpicsListRoot from 'ee/epics_list/components/epics_list_root.vue';
import { EpicsSortOptions } from 'ee/epics_list/constants';
import { mockFormattedEpic } from 'ee_jest/roadmap/mock_data';
import { stubComponent } from 'helpers/stub_component';
import { mockAuthor, mockLabels } from 'jest/vue_shared/issuable/list/mock_data';

import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableListTabs } from '~/vue_shared/issuable/list/constants';

jest.mock('~/vue_shared/issuable/list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
  IssuableListTabs: jest.requireActual('~/vue_shared/issuable/list/constants').IssuableListTabs,
  AvailableSortOptions: jest.requireActual('~/vue_shared/issuable/list/constants')
    .AvailableSortOptions,
}));

const mockRawEpic = {
  ...pick(mockFormattedEpic, [
    'title',
    'createdAt',
    'updatedAt',
    'webUrl',
    'userDiscussionsCount',
    'confidential',
  ]),
  author: mockAuthor,
  labels: {
    nodes: mockLabels,
  },
  startDate: '2021-04-01',
  dueDate: '2021-06-30',
};

const mockEpics = new Array(5)
  .fill()
  .map((_, i) => ({ ...mockRawEpic, id: i + 1, iid: (i + 1) * 10 }));

const mockProvide = {
  canCreateEpic: true,
  canBulkEditEpics: true,
  page: 1,
  prev: '',
  next: '',
  initialState: 'opened',
  initialSortBy: 'created_desc',
  epicsCount: {
    opened: 5,
    closed: 0,
    all: 5,
  },
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

const createComponent = ({
  provide = mockProvide,
  initialFilterParams = {},
  epicsLoading = false,
  epicsList = mockEpics,
} = {}) =>
  shallowMount(EpicsListRoot, {
    propsData: {
      initialFilterParams,
    },
    provide,
    mocks: {
      $apollo: {
        queries: {
          epics: {
            loading: epicsLoading,
            list: epicsList,
            pageInfo: mockPageInfo,
          },
        },
      },
    },
    stubs: {
      IssuableList: stubComponent(IssuableList),
    },
  });

describe('EpicsListRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
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

    describe('fetchEpicsBy', () => {
      it('updates prevPageCursor and nextPageCursor values when provided propsName param is "currentPage"', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          epics: {
            pageInfo: mockPageInfo,
          },
        });
        wrapper.vm.fetchEpicsBy('currentPage', 2);

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe(mockPageInfo.endCursor);
        expect(wrapper.vm.currentPage).toBe(2);
      });
    });
  });

  describe('template', () => {
    const getIssuableList = () => wrapper.findComponent(IssuableList);

    it('renders issuable-list component', async () => {
      jest.spyOn(wrapper.vm, 'getFilteredSearchTokens');
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        filterParams: {
          search: 'foo',
        },
      });

      await wrapper.vm.$nextTick();

      expect(getIssuableList().exists()).toBe(true);
      expect(getIssuableList().props()).toMatchObject({
        namespace: mockProvide.groupFullPath,
        tabs: IssuableListTabs,
        currentTab: 'opened',
        tabCounts: mockProvide.epicsCount,
        searchInputPlaceholder: 'Search or filter results...',
        sortOptions: EpicsSortOptions,
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

        await wrapper.vm.$nextTick();

        expect(getIssuableList().props('showPaginationControls')).toBe(returnValue);
      },
    );

    it('sets previousPage prop value a number representing previous page based on currentPage value', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        currentPage: 3,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.vm.previousPage).toBe(2);
    });

    it('sets nextPage prop value a number representing next page based on currentPage value', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        currentPage: 1,
        epicsCount: {
          opened: 5,
          closed: 0,
          all: 5,
        },
      });

      await wrapper.vm.$nextTick();

      expect(getIssuableList().props('nextPage')).toBe(2);
    });

    it('sets nextPage prop value as `null` when currentPage is already last page', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        currentPage: 3,
        epicsCount: {
          opened: 5,
          closed: 0,
          all: 5,
        },
      });

      await wrapper.vm.$nextTick();

      expect(getIssuableList().props('nextPage')).toBeNull();
    });
  });
});
