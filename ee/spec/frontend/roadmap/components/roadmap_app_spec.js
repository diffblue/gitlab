import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import Cookies from 'js-cookie';
import Vuex from 'vuex';
import EpicsListEmpty from 'ee/roadmap/components/epics_list_empty.vue';
import RoadmapApp from 'ee/roadmap/components/roadmap_app.vue';
import RoadmapFilters from 'ee/roadmap/components/roadmap_filters.vue';
import RoadmapShell from 'ee/roadmap/components/roadmap_shell.vue';
import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';
import eventHub from 'ee/roadmap/event_hub';
import createStore from 'ee/roadmap/store';
import * as types from 'ee/roadmap/store/mutation_types';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import {
  basePath,
  mockFormattedEpic,
  mockFormattedChildEpic2,
  mockGroupId,
  mockSortedBy,
  mockSvgPath,
  mockTimeframeInitialDate,
  rawEpics,
} from 'ee_jest/roadmap/mock_data';

describe('RoadmapApp', () => {
  const localVue = createLocalVue();
  let store;
  let wrapper;

  localVue.use(Vuex);

  const currentGroupId = mockGroupId;
  const emptyStateIllustrationPath = mockSvgPath;
  const epics = [mockFormattedEpic];
  const hasFiltersApplied = true;
  const presetType = PRESET_TYPES.MONTHS;
  const timeframe = getTimeframeForMonthsView(mockTimeframeInitialDate);

  const createComponent = (mountFunction = shallowMount) => {
    return mountFunction(RoadmapApp, {
      localVue,
      propsData: {
        emptyStateIllustrationPath,
        presetType,
      },
      provide: {
        glFeatures: { asyncFiltering: true },
        groupFullPath: 'gitlab-org',
        groupMilestonesPath: '/groups/gitlab-org/-/milestones.json',
        listEpicsPath: '/groups/gitlab-org/-/epics',
      },
      store,
    });
  };

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
    wrapper = null;
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

    it('contains path for the empty state illustration', () => {
      expect(wrapper.find(EpicsListEmpty).props('emptyStateIllustrationPath')).toBe(
        emptyStateIllustrationPath,
      );
    });

    it('contains whether to apply filters', () => {
      expect(wrapper.find(EpicsListEmpty).props('hasFiltersApplied')).toBe(hasFiltersApplied);
    });

    it('contains whether it is child epics', () => {
      expect(wrapper.find(EpicsListEmpty).props('isChildEpics')).toBe(false);
    });

    it('contains the preset type', () => {
      expect(wrapper.find(EpicsListEmpty).props('presetType')).toBe(presetType);
    });

    it('contains the start of the timeframe', () => {
      expect(wrapper.find(EpicsListEmpty).props('timeframeStart')).toStrictEqual(timeframe[0]);
    });

    it('contains the end of the timeframe', () => {
      expect(wrapper.find(EpicsListEmpty).props('timeframeEnd')).toStrictEqual(
        timeframe[timeframe.length - 1],
      );
    });
  });

  describe('roadmap view', () => {
    beforeEach(() => {
      wrapper = createComponent();
      store.commit(types.RECEIVE_EPICS_SUCCESS, { epics });
    });

    it('contains roadmap filters UI', () => {
      expect(wrapper.find(RoadmapFilters).exists()).toBe(true);
    });

    it('contains the current group id', () => {
      expect(wrapper.find(RoadmapShell).props('currentGroupId')).toBe(currentGroupId);
    });

    it('contains epics', () => {
      expect(wrapper.find(RoadmapShell).props('epics')).toEqual(epics);
    });

    it('contains whether filters are applied', () => {
      expect(wrapper.find(RoadmapShell).props('hasFiltersApplied')).toBe(hasFiltersApplied);
    });

    it('contains milestones', () => {
      expect(wrapper.find(RoadmapShell).props('milestones')).toEqual([]);
    });

    it('contains the preset type', () => {
      expect(wrapper.find(RoadmapShell).props('presetType')).toBe(presetType);
    });

    it('contains timeframe', () => {
      expect(wrapper.find(RoadmapShell).props('timeframe')).toEqual(timeframe);
    });
  });

  describe('extending the roadmap timeline', () => {
    let roadmapTimelineEl;

    beforeEach(() => {
      store.dispatch('receiveEpicsSuccess', { rawEpics: rawEpics.slice(0, 2) });
      wrapper = createComponent(mount);
      roadmapTimelineEl = wrapper.find('.roadmap-timeline-section').element;
    });

    it('updates timeline by extending timeframe from the start when called with extendType as `prepend`', () => {
      jest.spyOn(eventHub, '$emit').mockImplementation();

      wrapper.vm.processExtendedTimeline({
        extendType: EXTEND_AS.PREPEND,
        roadmapTimelineEl,
        itemsCount: 0,
      });

      expect(eventHub.$emit).toHaveBeenCalledWith('refreshTimeline', expect.any(Object));
      expect(roadmapTimelineEl.parentElement.scrollBy).toHaveBeenCalled();
    });

    it('updates timeline by extending timeframe from the end when called with extendType as `append`', () => {
      jest.spyOn(eventHub, '$emit').mockImplementation();

      wrapper.vm.processExtendedTimeline({
        extendType: EXTEND_AS.APPEND,
        roadmapTimelineEl,
        itemsCount: 0,
      });

      expect(eventHub.$emit).toHaveBeenCalledWith('refreshTimeline', expect.any(Object));
    });

    it('updates the store and refreshes roadmap with extended timeline based on provided extendType', () => {
      jest.spyOn(wrapper.vm, 'extendTimeframe').mockImplementation();
      jest.spyOn(wrapper.vm, 'refreshEpicDates').mockImplementation();
      jest.spyOn(wrapper.vm, 'refreshMilestoneDates').mockImplementation();
      jest.spyOn(wrapper.vm, 'fetchEpicsForTimeframe').mockResolvedValue();

      const extendType = EXTEND_AS.PREPEND;

      wrapper.vm.handleScrollToExtend(roadmapTimelineEl, extendType);

      expect(wrapper.vm.extendTimeframe).toHaveBeenCalledWith({ extendAs: extendType });
      expect(wrapper.vm.refreshEpicDates).toHaveBeenCalled();
      expect(wrapper.vm.refreshMilestoneDates).toHaveBeenCalled();
    });

    it('calls `fetchEpicsForTimeframe` with extended timeframe array', () => {
      jest.spyOn(wrapper.vm, 'fetchEpicsForTimeframe').mockResolvedValue();

      const extendType = EXTEND_AS.PREPEND;

      wrapper.vm.handleScrollToExtend(roadmapTimelineEl, extendType);

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.fetchEpicsForTimeframe).toHaveBeenCalledWith(
          expect.objectContaining({
            timeframe: wrapper.vm.extendedTimeframe,
          }),
        );
      });
    });
  });

  describe('roadmap epics limit warning', () => {
    beforeEach(() => {
      wrapper = createComponent();
      store.commit(types.RECEIVE_EPICS_SUCCESS, {
        epics: [mockFormattedEpic, mockFormattedChildEpic2],
      });
      window.gon.roadmap_epics_limit = 1;
    });

    it('displays warning when epics limit is reached', () => {
      expect(wrapper.find(GlAlert).exists()).toBe(true);
      expect(wrapper.find(GlAlert).text()).toContain(
        'Roadmaps can display up to 1,000 epics. These appear in your selected sort order.',
      );
    });

    it('sets epics_limit_warning_dismissed cookie to true when dismissing alert', () => {
      wrapper.find(GlAlert).vm.$emit('dismiss');

      expect(Cookies.get('epics_limit_warning_dismissed')).toBe('true');

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(GlAlert).exists()).toBe(false);
      });
    });
  });
});
