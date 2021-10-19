import Vue from 'vue';

import roadmapTimelineSectionComponent from 'ee/roadmap/components/roadmap_timeline_section.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import eventHub from 'ee/roadmap/event_hub';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockEpic, mockTimeframeInitialDate } from 'ee_jest/roadmap/mock_data';
import mountComponent from 'helpers/vue_mount_component_helper';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  epics = [mockEpic],
  timeframe = mockTimeframeMonths,
} = {}) => {
  const Component = Vue.extend(roadmapTimelineSectionComponent);

  return mountComponent(Component, {
    presetType,
    epics,
    timeframe,
  });
};

describe('RoadmapTimelineSectionComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.scrolledHeaderClass).toBe('');
    });
  });

  describe('computed', () => {
    describe('sectionContainerStyles', () => {
      it('returns object containing `width` with value based on epic details cell width, timeline cell width and timeframe length', () => {
        expect(vm.sectionContainerStyles).toEqual(
          expect.objectContaining({
            width: '2480px', // We now have fixed columns in timeframe.
          }),
        );
      });
    });
  });

  describe('methods', () => {
    describe('handleEpicsListScroll', () => {
      it('sets `scrolled-ahead` class on thead element based on provided scrollTop value', () => {
        // vm.$el.clientHeight is 0 during tests
        // hence any value greater than 0 should
        // update scrolledHeaderClass prop
        vm.handleEpicsListScroll({ scrollTop: 1 });

        expect(vm.scrolledHeaderClass).toBe('scroll-top-shadow');

        vm.handleEpicsListScroll({ scrollTop: 0 });

        expect(vm.scrolledHeaderClass).toBe('');
      });
    });
  });

  describe('mounted', () => {
    it('binds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});
      const vmX = createComponent({});

      expect(eventHub.$on).toHaveBeenCalledWith('epicsListScrolled', expect.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$off').mockImplementation(() => {});
      const vmX = createComponent({});
      vmX.$destroy();

      expect(eventHub.$off).toHaveBeenCalledWith('epicsListScrolled', expect.any(Function));
    });
  });

  describe('template', () => {
    it('renders component container element with class `roadmap-timeline-section`', () => {
      expect(vm.$el.classList.contains('roadmap-timeline-section')).toBe(true);
    });

    it('renders empty header cell element with class `timeline-header-blank`', () => {
      expect(vm.$el.querySelector('.timeline-header-blank')).not.toBeNull();
    });
  });
});
