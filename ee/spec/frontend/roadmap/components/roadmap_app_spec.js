import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EpicsListEmpty from 'ee/roadmap/components/epics_list_empty.vue';
import RoadmapApp from 'ee/roadmap/components/roadmap_app.vue';
import RoadmapFilters from 'ee/roadmap/components/roadmap_filters.vue';
import RoadmapShell from 'ee/roadmap/components/roadmap_shell.vue';
import { PRESET_TYPES, DATE_RANGES } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import * as types from 'ee/roadmap/store/mutation_types';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import {
  basePath,
  mockFormattedEpic,
  mockGroupId,
  mockSortedBy,
  mockSvgPath,
  mockTimeframeInitialDate,
} from 'ee_jest/roadmap/mock_data';

Vue.use(Vuex);

describe('RoadmapApp', () => {
  let store;
  let wrapper;

  const currentGroupId = mockGroupId;
  const emptyStateIllustrationPath = mockSvgPath;
  const epics = [mockFormattedEpic];
  const hasFiltersApplied = true;
  const presetType = PRESET_TYPES.MONTHS;
  const timeframe = getTimeframeForRangeType({
    timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
    presetType: PRESET_TYPES.MONTHS,
    initialDate: mockTimeframeInitialDate,
  });

  const createComponent = ({ roadmapSettings = false } = {}) => {
    return shallowMountExtended(RoadmapApp, {
      propsData: {
        emptyStateIllustrationPath,
        presetType,
      },
      provide: {
        groupFullPath: 'gitlab-org',
        groupMilestonesPath: '/groups/gitlab-org/-/milestones.json',
        listEpicsPath: '/groups/gitlab-org/-/epics',
        glFeatures: { roadmapSettings },
      },
      store,
    });
  };

  const findSettingsSidebar = () => wrapper.findByTestId('roadmap-settings');

  beforeEach(() => {
    store = createStore();
    store.dispatch('setInitialData', {
      currentGroupId,
      sortedBy: mockSortedBy,
      presetType,
      timeframe,
      hasFiltersApplied,
      filterQueryString: '',
      basePath,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    testLabel         | epicList | showLoading | showRoadmapShell | showEpicsListEmpty
    ${'is loading'}   | ${null}  | ${true}     | ${false}         | ${false}
    ${'has epics'}    | ${epics} | ${false}    | ${true}          | ${false}
    ${'has no epics'} | ${[]}    | ${false}    | ${false}         | ${true}
  `(
    `when epic list $testLabel`,
    ({ epicList, showLoading, showRoadmapShell, showEpicsListEmpty }) => {
      beforeEach(() => {
        wrapper = createComponent();
        if (epicList) {
          store.commit(types.RECEIVE_EPICS_SUCCESS, { epics: epicList });
        }
      });

      it(`loading icon is${showLoading ? '' : ' not'} shown`, () => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(showLoading);
      });

      it(`roadmap is${showRoadmapShell ? '' : ' not'} shown`, () => {
        expect(wrapper.find(RoadmapShell).exists()).toBe(showRoadmapShell);
      });

      it(`empty state view is${showEpicsListEmpty ? '' : ' not'} shown`, () => {
        expect(wrapper.find(EpicsListEmpty).exists()).toBe(showEpicsListEmpty);
      });
    },
  );

  describe('empty state view', () => {
    beforeEach(() => {
      wrapper = createComponent();
      store.commit(types.RECEIVE_EPICS_SUCCESS, { epics: [] });
    });

    it('shows epic-list-empty component', () => {
      const epicsListEmpty = wrapper.findComponent(EpicsListEmpty);
      expect(epicsListEmpty.exists()).toBe(true);
      expect(epicsListEmpty.props()).toMatchObject({
        emptyStateIllustrationPath,
        hasFiltersApplied,
        presetType,
        timeframeStart: timeframe[0],
        timeframeEnd: timeframe[timeframe.length - 1],
        isChildEpics: false,
      });
    });
  });

  describe('roadmap view', () => {
    beforeEach(() => {
      wrapper = createComponent();
      store.commit(types.RECEIVE_EPICS_SUCCESS, { epics });
    });

    it('does not show filters UI when epicIid is present', async () => {
      store.dispatch('setInitialData', {
        epicIid: mockFormattedEpic.iid,
      });

      await nextTick();

      expect(wrapper.findComponent(RoadmapFilters).exists()).toBe(false);
    });

    it('shows roadmap filters UI when epicIid is not present', () => {
      // By default, `epicIid` is not set on store.
      expect(wrapper.findComponent(RoadmapFilters).exists()).toBe(true);
    });

    it('shows roadmap-shell component', () => {
      const roadmapShell = wrapper.findComponent(RoadmapShell);
      expect(wrapper.find(RoadmapShell).exists()).toBe(true);
      expect(roadmapShell.props()).toMatchObject({
        currentGroupId,
        epics,
        hasFiltersApplied,
        presetType,
        timeframe,
        milestones: [],
      });
    });

    it('does not render settings sidebar', () => {
      expect(findSettingsSidebar().exists()).toBe(false);
    });

    describe('when roadmapSettings feature flag is on', () => {
      beforeEach(() => {
        wrapper = createComponent({ roadmapSettings: true });
      });

      it('renders settings button', () => {
        expect(findSettingsSidebar().exists()).toBe(true);
      });
    });
  });
});
