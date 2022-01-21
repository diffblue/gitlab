import { GlSegmentedControl, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';

import RoadmapFilters from 'ee/roadmap/components/roadmap_filters.vue';
import { PRESET_TYPES, EPICS_STATES, DATE_RANGES } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import {
  mockSortedBy,
  mockTimeframeInitialDate,
  mockAuthorTokenConfig,
  mockLabelTokenConfig,
  mockMilestoneTokenConfig,
  mockConfidentialTokenConfig,
  mockEpicTokenConfig,
  mockReactionEmojiTokenConfig,
} from 'ee_jest/roadmap/mock_data';

import { TEST_HOST } from 'helpers/test_constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl, mergeUrlParams, updateHistory } from '~/lib/utils/url_utility';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  mergeUrlParams: jest.fn(),
  visitUrl: jest.fn(),
  setUrlParams: jest.requireActual('~/lib/utils/url_utility').setUrlParams,
  updateHistory: jest.requireActual('~/lib/utils/url_utility').updateHistory,
}));

Vue.use(Vuex);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  epicsState = EPICS_STATES.ALL,
  sortedBy = mockSortedBy,
  groupFullPath = 'gitlab-org',
  listEpicsPath = '/groups/gitlab-org/-/epics',
  groupMilestonesPath = '/groups/gitlab-org/-/milestones.json',
  timeframe = getTimeframeForRangeType({
    timeframeRangeType: DATE_RANGES.THREE_YEARS,
    presetType: PRESET_TYPES.MONTHS,
    initialDate: mockTimeframeInitialDate,
  }),
  filterParams = {},
  timeframeRangeType = DATE_RANGES.THREE_YEARS,
  roadmapSettings = false,
} = {}) => {
  const store = createStore();

  store.dispatch('setInitialData', {
    presetType,
    epicsState,
    sortedBy,
    filterParams,
    timeframe,
  });

  return shallowMountExtended(RoadmapFilters, {
    store,
    provide: {
      groupFullPath,
      groupMilestonesPath,
      listEpicsPath,
      glFeatures: { roadmapSettings },
    },
    props: {
      timeframeRangeType,
    },
  });
};

describe('RoadmapFilters', () => {
  let wrapper;
  const findSettingsButton = () => wrapper.findByTestId('settings-button');

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('selectedEpicStateTitle', () => {
      it.each`
        returnValue       | epicsState
        ${'All epics'}    | ${EPICS_STATES.ALL}
        ${'Open epics'}   | ${EPICS_STATES.OPENED}
        ${'Closed epics'} | ${EPICS_STATES.CLOSED}
      `(
        'returns string "$returnValue" when epicsState represents `$epicsState`',
        ({ returnValue, epicsState }) => {
          wrapper.vm.$store.dispatch('setEpicsState', epicsState);

          expect(wrapper.vm.selectedEpicStateTitle).toBe(returnValue);
        },
      );
    });
  });

  describe('watch', () => {
    describe('urlParams', () => {
      it('updates window URL based on presence of props for state, filtered search and sort criteria', async () => {
        wrapper.vm.$store.dispatch('setEpicsState', EPICS_STATES.CLOSED);
        wrapper.vm.$store.dispatch('setFilterParams', {
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
        });
        wrapper.vm.$store.dispatch('setSortedBy', 'end_date_asc');

        await wrapper.vm.$nextTick();

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?state=${EPICS_STATES.CLOSED}&sort=end_date_asc&layout=MONTHS&author_username=root&label_name%5B%5D=Bug&milestone_title=4.0&confidential=true`,
        );
      });
    });
  });

  describe('template', () => {
    const quarters = { text: 'Quarters', value: PRESET_TYPES.QUARTERS };
    const months = { text: 'Months', value: PRESET_TYPES.MONTHS };
    const weeks = { text: 'Weeks', value: PRESET_TYPES.WEEKS };

    beforeEach(() => {
      updateHistory({ url: TEST_HOST, title: document.title, replace: true });
    });

    it('switching layout using roadmap layout switching buttons causes page to reload with selected layout', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ selectedDaterange: DATE_RANGES.THREE_YEARS });

      await wrapper.vm.$nextTick();

      wrapper.findComponent(GlSegmentedControl).vm.$emit('input', PRESET_TYPES.OPENED);

      expect(mergeUrlParams).toHaveBeenCalledWith(
        expect.objectContaining({ layout: PRESET_TYPES.OPENED }),
        `${TEST_HOST}/`,
      );
      expect(visitUrl).toHaveBeenCalled();
    });

    it('renders epics state toggling dropdown', () => {
      const epicsStateDropdown = wrapper.find(GlDropdown);

      expect(epicsStateDropdown.exists()).toBe(true);
      expect(epicsStateDropdown.findAll(GlDropdownItem)).toHaveLength(3);
    });

    it('does not render settings button', () => {
      expect(findSettingsButton().exists()).toBe(false);
    });

    describe('FilteredSearchBar', () => {
      const mockInitialFilterValue = [
        {
          type: 'author_username',
          value: { data: 'root', operator: '=' },
        },
        {
          type: 'author_username',
          value: { data: 'John', operator: '!=' },
        },
        {
          type: 'label_name',
          value: { data: 'Bug', operator: '=' },
        },
        {
          type: 'label_name',
          value: { data: 'Feature', operator: '!=' },
        },
        {
          type: 'milestone_title',
          value: { data: '4.0' },
        },
        {
          type: 'confidential',
          value: { data: true },
        },
        {
          type: 'my_reaction_emoji',
          value: { data: 'thumbs_up', operator: '!=' },
        },
      ];
      let filteredSearchBar;

      beforeEach(() => {
        filteredSearchBar = wrapper.find(FilteredSearchBar);
      });

      it('component is rendered with correct namespace & recent search key', () => {
        expect(filteredSearchBar.exists()).toBe(true);
        expect(filteredSearchBar.props('namespace')).toBe('gitlab-org');
        expect(filteredSearchBar.props('recentSearchesStorageKey')).toBe('epics');
      });

      it('includes `Author`, `Milestone`, `Confidential`, `Epic` and `Label` tokens when user is not logged in', () => {
        expect(filteredSearchBar.props('tokens')).toEqual([
          mockAuthorTokenConfig,
          mockConfidentialTokenConfig,
          mockEpicTokenConfig,
          mockLabelTokenConfig,
          mockMilestoneTokenConfig,
        ]);
      });

      it('includes "Start date" and "Due date" sort options', () => {
        expect(filteredSearchBar.props('sortOptions')).toEqual([
          {
            id: 1,
            title: 'Start date',
            sortDirection: {
              descending: 'start_date_desc',
              ascending: 'start_date_asc',
            },
          },
          {
            id: 2,
            title: 'Due date',
            sortDirection: {
              descending: 'end_date_desc',
              ascending: 'end_date_asc',
            },
          },
        ]);
      });

      it('has initialFilterValue prop set to array of formatted values based on `filterParams`', async () => {
        wrapper.vm.$store.dispatch('setFilterParams', {
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
          'not[authorUsername]': 'John',
          'not[labelName]': ['Feature'],
          'not[myReactionEmoji]': 'thumbs_up',
        });

        await wrapper.vm.$nextTick();

        expect(filteredSearchBar.props('initialFilterValue')).toEqual(mockInitialFilterValue);
      });

      it('fetches filtered epics when `onFilter` event is emitted', async () => {
        jest.spyOn(wrapper.vm, 'setFilterParams');
        jest.spyOn(wrapper.vm, 'fetchEpics');

        await wrapper.vm.$nextTick();

        filteredSearchBar.vm.$emit('onFilter', mockInitialFilterValue);

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.setFilterParams).toHaveBeenCalledWith({
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
          'not[authorUsername]': 'John',
          'not[labelName]': ['Feature'],
          'not[myReactionEmoji]': 'thumbs_up',
        });
        expect(wrapper.vm.fetchEpics).toHaveBeenCalled();
      });

      it('fetches epics with updated sort order when `onSort` event is emitted', async () => {
        jest.spyOn(wrapper.vm, 'setSortedBy');
        jest.spyOn(wrapper.vm, 'fetchEpics');

        await wrapper.vm.$nextTick();

        filteredSearchBar.vm.$emit('onSort', 'end_date_asc');

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.setSortedBy).toHaveBeenCalledWith('end_date_asc');
        expect(wrapper.vm.fetchEpics).toHaveBeenCalled();
      });

      it('does not set filters params or fetch epics when onFilter event is triggered with empty filters array and cleared param set to false', async () => {
        jest.spyOn(wrapper.vm, 'setFilterParams');
        jest.spyOn(wrapper.vm, 'fetchEpics');

        filteredSearchBar.vm.$emit('onFilter', [], false);

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.setFilterParams).not.toHaveBeenCalled();
        expect(wrapper.vm.fetchEpics).not.toHaveBeenCalled();
      });

      describe('when user is logged in', () => {
        beforeAll(() => {
          gon.current_user_id = 1;
          gon.current_user_fullname = 'Administrator';
          gon.current_username = 'root';
          gon.current_user_avatar_url = 'avatar/url';
        });

        it('includes `Author`, `Milestone`, `Confidential`, `Label` and `My-Reaction` tokens', () => {
          expect(filteredSearchBar.props('tokens')).toEqual([
            {
              ...mockAuthorTokenConfig,
              preloadedAuthors: [
                {
                  id: 1,
                  name: 'Administrator',
                  username: 'root',
                  avatar_url: 'avatar/url',
                },
              ],
            },
            mockConfidentialTokenConfig,
            mockEpicTokenConfig,
            mockLabelTokenConfig,
            mockMilestoneTokenConfig,
            mockReactionEmojiTokenConfig,
          ]);
        });
      });
    });

    describe('daterange filtering', () => {
      let wrapperWithDaterangeFilter;
      const availableRanges = [
        { text: 'This quarter', value: DATE_RANGES.CURRENT_QUARTER },
        { text: 'This year', value: DATE_RANGES.CURRENT_YEAR },
        { text: 'Within 3 years', value: DATE_RANGES.THREE_YEARS },
      ];

      beforeEach(async () => {
        wrapperWithDaterangeFilter = createComponent({
          timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
        });

        await wrapperWithDaterangeFilter.vm.$nextTick();
      });

      afterEach(() => {
        wrapperWithDaterangeFilter.destroy();
      });

      it('renders daterange dropdown', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapperWithDaterangeFilter.setData({ selectedDaterange: DATE_RANGES.CURRENT_QUARTER });
        await wrapperWithDaterangeFilter.vm.$nextTick();

        const daterangeDropdown = wrapperWithDaterangeFilter.findByTestId('daterange-dropdown');

        expect(daterangeDropdown.exists()).toBe(true);
        expect(daterangeDropdown.props('text')).toBe('This quarter');
        daterangeDropdown.findAllComponents(GlDropdownItem).wrappers.forEach((item, index) => {
          expect(item.text()).toBe(availableRanges[index].text);
          expect(item.attributes('value')).toBe(availableRanges[index].value);
        });
      });

      it.each`
        selectedDaterange              | availablePresets
        ${DATE_RANGES.CURRENT_QUARTER} | ${[]}
        ${DATE_RANGES.CURRENT_YEAR}    | ${[months, weeks]}
        ${DATE_RANGES.THREE_YEARS}     | ${[quarters, months, weeks]}
      `(
        'renders $availablePresets.length items when selected daterange is "$selectedDaterange"',
        async ({ selectedDaterange, availablePresets }) => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapperWithDaterangeFilter.setData({ selectedDaterange });
          await wrapperWithDaterangeFilter.vm.$nextTick();

          const layoutSwitches = wrapperWithDaterangeFilter.findComponent(GlSegmentedControl);

          if (selectedDaterange === DATE_RANGES.CURRENT_QUARTER) {
            expect(layoutSwitches.exists()).toBe(false);
          } else {
            expect(layoutSwitches.exists()).toBe(true);
            expect(layoutSwitches.props('options')).toEqual(availablePresets);
          }
        },
      );
    });
  });

  describe('when roadmapSettings feature flag is on', () => {
    beforeEach(() => {
      wrapper = createComponent({ roadmapSettings: true });
    });

    it('renders settings button', () => {
      expect(findSettingsButton().exists()).toBe(true);
    });

    it('emits toggleSettings event on click settings button', () => {
      findSettingsButton().vm.$emit('click');

      expect(wrapper.emitted('toggleSettings')).toBeTruthy();
    });
  });
});
