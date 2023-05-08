import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import EpicsListSection from 'ee/roadmap/components/epics_list_section.vue';
import MilestonesListSection from 'ee/roadmap/components/milestones_list_section.vue';
import MonthsHeaderItem from 'ee/roadmap/components/preset_months/months_header_item.vue';
import MonthsHeaderSubItem from 'ee/roadmap/components/preset_months/months_header_sub_item.vue';
import RoadmapShell from 'ee/roadmap/components/roadmap_shell.vue';
import RoadmapTimelineSection from 'ee/roadmap/components/roadmap_timeline_section.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import eventHub from 'ee/roadmap/event_hub';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockEpic, mockTimeframeInitialDate, mockGroupId } from 'ee_jest/roadmap/mock_data';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const presetType = PRESET_TYPES.MONTHS;
const timeframeRangeType = DATE_RANGES.CURRENT_YEAR;

describe('RoadmapShell', () => {
  Vue.use(Vuex);

  let store;
  let wrapper;

  const storeFactory = ({ defaultInnerHeight = 0 }) => {
    store = createStore();
    store.dispatch('setInitialData', {
      defaultInnerHeight,
      childrenFlags: { 1: { itemExpanded: false } },
      timeframe: mockTimeframeMonths,
      presetType,
      timeframeRangeType,
      filterParams: {
        milestoneTitle: '',
      },
    });
  };

  const createComponent = (
    {
      epics = [mockEpic],
      timeframe = mockTimeframeMonths,
      currentGroupId = mockGroupId,
      hasFiltersApplied = false,
    },
    el,
  ) => {
    wrapper = shallowMount(RoadmapShell, {
      store,
      attachTo: el,
      propsData: {
        presetType: PRESET_TYPES.MONTHS,
        epics,
        timeframe,
        currentGroupId,
        hasFiltersApplied,
      },
      stubs: {
        RoadmapTimelineSection,
        MilestonesListSection,
        EpicsListSection,
        MonthsHeaderItem,
        MonthsHeaderSubItem,
      },
    });
  };

  beforeEach(() => {
    storeFactory({});
    createComponent({});
  });

  afterEach(() => {
    store = null;
  });

  describe('methods', () => {
    beforeEach(() => {
      document.body.innerHTML +=
        '<div class="roadmap-container"><div data-testid="roadmap-shell"></div></div>';
      createComponent({}, document.querySelector('[data-testid="roadmap-shell"]'));
    });

    afterEach(() => {
      document.querySelector('.roadmap-container').remove();
    });

    describe('handleScroll', () => {
      it('emits `epicsListScrolled` event via eventHub', async () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        await nextTick();
        wrapper.vm.handleScroll();

        expect(eventHub.$emit).toHaveBeenCalledWith('epicsListScrolled', expect.any(Object));
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `js-roadmap-shell`', () => {
      expect(wrapper.find('.js-roadmap-shell').exists()).toBe(true);
    });

    it('sets style attribute containing computed height', () => {
      expect(wrapper.attributes('style')).toBe('height: calc(100vh - 0px);');
    });
  });
});
