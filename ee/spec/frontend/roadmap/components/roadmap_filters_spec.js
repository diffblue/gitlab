import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import RoadmapFilters from 'ee/roadmap/components/roadmap_filters.vue';
import { PRESET_TYPES, DATE_RANGES, PROGRESS_WEIGHT, MILESTONES_ALL } from 'ee/roadmap/constants';
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
  mockGroupTokenConfig,
} from 'ee_jest/roadmap/mock_data';

import { TEST_HOST } from 'helpers/test_constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { STATUS_ALL, STATUS_CLOSED } from '~/issues/constants';
import { updateHistory } from '~/lib/utils/url_utility';
import {
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  setUrlParams: jest.requireActual('~/lib/utils/url_utility').setUrlParams,
  updateHistory: jest.requireActual('~/lib/utils/url_utility').updateHistory,
}));

Vue.use(Vuex);

describe('RoadmapFilters', () => {
  let wrapper;
  let store;

  const createComponent = ({
    presetType = PRESET_TYPES.MONTHS,
    epicsState = STATUS_ALL,
    sortedBy = mockSortedBy,
    groupFullPath = 'gitlab-org',
    groupMilestonesPath = '/groups/gitlab-org/-/milestones.json',
    timeframe = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.THREE_YEARS,
      presetType: PRESET_TYPES.MONTHS,
      initialDate: mockTimeframeInitialDate,
    }),
    filterParams = {},
  } = {}) => {
    store = createStore();

    store.dispatch('setInitialData', {
      presetType,
      epicsState,
      sortedBy,
      filterParams,
      timeframe,
      isProgressTrackingActive: true,
      progressTracking: PROGRESS_WEIGHT,
      milestonesType: MILESTONES_ALL,
    });

    return shallowMountExtended(RoadmapFilters, {
      store,
      provide: {
        groupFullPath,
        groupMilestonesPath,
      },
    });
  };

  const findSettingsButton = () => wrapper.findByTestId('settings-button');

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('watch', () => {
    describe('urlParams', () => {
      it('updates window URL based on presence of props for state, filtered search and sort criteria', async () => {
        store.dispatch('setEpicsState', STATUS_CLOSED);
        store.dispatch('setFilterParams', {
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
        });
        store.dispatch('setSortedBy', 'end_date_asc');
        store.dispatch('setDaterange', {
          timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
          presetType: PRESET_TYPES.MONTHS,
        });

        await nextTick();

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?state=${STATUS_CLOSED}&sort=end_date_asc&layout=MONTHS&timeframe_range_type=CURRENT_YEAR&author_username=root&label_name[]=Bug&milestone_title=4.0&confidential=true&progress=WEIGHT&show_progress=true&show_milestones=true&milestones_type=ALL&show_labels=false`,
        );
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      updateHistory({ url: TEST_HOST, title: document.title, replace: true });
    });

    it('renders settings button', () => {
      expect(findSettingsButton().exists()).toBe(true);
    });

    it('emits toggleSettings event on click settings button', () => {
      findSettingsButton().vm.$emit('click');

      expect(wrapper.emitted('toggleSettings')).toHaveLength(1);
    });

    describe('FilteredSearchBar', () => {
      const mockInitialFilterValue = [
        {
          type: TOKEN_TYPE_AUTHOR,
          value: { data: 'root', operator: '=' },
        },
        {
          type: TOKEN_TYPE_AUTHOR,
          value: { data: 'John', operator: '!=' },
        },
        {
          type: TOKEN_TYPE_LABEL,
          value: { data: 'Bug', operator: '=' },
        },
        {
          type: TOKEN_TYPE_LABEL,
          value: { data: 'Feature', operator: '!=' },
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          value: { data: '4.0' },
        },
        {
          type: TOKEN_TYPE_CONFIDENTIAL,
          value: { data: true },
        },
        {
          type: TOKEN_TYPE_MY_REACTION,
          value: { data: 'thumbs_up', operator: '!=' },
        },
      ];
      let filteredSearchBar;

      beforeEach(() => {
        filteredSearchBar = wrapper.findComponent(FilteredSearchBar);
      });

      it('component is rendered with correct namespace & recent search key', () => {
        expect(filteredSearchBar.exists()).toBe(true);
        expect(filteredSearchBar.props('namespace')).toBe('gitlab-org');
        expect(filteredSearchBar.props('recentSearchesStorageKey')).toBe('epics');
      });

      it('includes `Author`, `Milestone`, `Confidential`, `Epic`, `Group`, and `Label` tokens when user is not logged in', () => {
        expect(filteredSearchBar.props('tokens')).toEqual([
          mockAuthorTokenConfig,
          mockConfidentialTokenConfig,
          mockEpicTokenConfig,
          mockGroupTokenConfig,
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
        store.dispatch('setFilterParams', {
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
          'not[authorUsername]': 'John',
          'not[labelName]': ['Feature'],
          'not[myReactionEmoji]': 'thumbs_up',
        });

        await nextTick();

        expect(filteredSearchBar.props('initialFilterValue')).toEqual(mockInitialFilterValue);
      });

      it('fetches filtered epics when `onFilter` event is emitted', async () => {
        jest.spyOn(store, 'dispatch');

        await nextTick();

        filteredSearchBar.vm.$emit('onFilter', mockInitialFilterValue);

        await nextTick();

        expect(store.dispatch).toHaveBeenCalledWith('setFilterParams', {
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
          'not[authorUsername]': 'John',
          'not[labelName]': ['Feature'],
          'not[myReactionEmoji]': 'thumbs_up',
        });
        expect(store.dispatch).toHaveBeenCalledWith('fetchEpics');
      });

      it('fetches epics with updated sort order when `onSort` event is emitted', async () => {
        jest.spyOn(store, 'dispatch');

        await nextTick();

        filteredSearchBar.vm.$emit('onSort', 'end_date_asc');

        await nextTick();

        expect(store.dispatch).toHaveBeenCalledWith('setSortedBy', 'end_date_asc');
        expect(store.dispatch).toHaveBeenCalledWith('fetchEpics');
      });

      it('does not set filters params or fetch epics when onFilter event is triggered with empty filters array and cleared param set to false', async () => {
        jest.spyOn(store, 'dispatch');

        filteredSearchBar.vm.$emit('onFilter', [], false);

        await nextTick();

        expect(store.dispatch).not.toHaveBeenCalledWith('setFilterParams');
        expect(store.dispatch).not.toHaveBeenCalledWith('fetchEpics');
      });

      describe('when user is logged in', () => {
        beforeEach(() => {
          gon.current_user_id = 1;
          gon.current_user_fullname = 'Administrator';
          gon.current_username = 'root';
          gon.current_user_avatar_url = 'avatar/url';

          wrapper = createComponent();
          filteredSearchBar = wrapper.findComponent(FilteredSearchBar);
        });

        it('includes `Author`, `Milestone`, `Confidential`, `Epic`, `Group`, `Label` and `My-Reaction` tokens', () => {
          expect(filteredSearchBar.props('tokens')).toEqual([
            {
              ...mockAuthorTokenConfig,
              preloadedUsers: [
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
            mockGroupTokenConfig,
            mockLabelTokenConfig,
            mockMilestoneTokenConfig,
            mockReactionEmojiTokenConfig,
          ]);
        });
      });
    });
  });
});
