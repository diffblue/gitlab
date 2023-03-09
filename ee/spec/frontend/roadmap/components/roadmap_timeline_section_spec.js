import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';

import RoadmapTimelineSectionComponent from 'ee/roadmap/components/roadmap_timeline_section.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import eventHub from 'ee/roadmap/event_hub';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockEpic, mockTimeframeInitialDate } from 'ee_jest/roadmap/mock_data';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

describe('RoadmapTimelineSectionComponent', () => {
  let wrapper;

  const createComponent = ({
    presetType = PRESET_TYPES.MONTHS,
    epics = [mockEpic],
    timeframe = mockTimeframeMonths,
  } = {}) => {
    wrapper = mount(RoadmapTimelineSectionComponent, {
      propsData: {
        presetType,
        epics,
        timeframe,
      },
    });
  };

  describe('section container styles', () => {
    it('`width` value based on epic details cell width, timeline cell width and timeframe length', () => {
      createComponent();

      expect(wrapper.element.style.width).toBe('2480px'); // We now have fixed columns in timeframe.
    });
  });

  describe('on epicsListScrolled hub event', () => {
    it('sets `scrolled-ahead` class on thead element based on provided scrollTop value', async () => {
      createComponent();

      eventHub.$emit('epicsListScrolled', { scrollTop: 1 });
      await nextTick();

      expect(wrapper.classes()).toContain('scroll-top-shadow');

      eventHub.$emit('epicsListScrolled', { scrollTop: 0 });
      await nextTick();

      expect(wrapper.classes()).not.toContain('scroll-top-shadow');
    });
  });

  describe('mounted', () => {
    it('binds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});
      createComponent();

      expect(eventHub.$on).toHaveBeenCalledWith('epicsListScrolled', expect.any(Function));
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$off').mockImplementation(() => {});
      createComponent();
      wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith('epicsListScrolled', expect.any(Function));
    });
  });

  it('renders component container element with class `roadmap-timeline-section`', () => {
    createComponent();

    expect(wrapper.classes()).toContain('roadmap-timeline-section');
  });

  it('renders empty header cell element with class `timeline-header-blank`', () => {
    createComponent();

    expect(wrapper.find('.timeline-header-blank').exists()).toBe(true);
  });
});
