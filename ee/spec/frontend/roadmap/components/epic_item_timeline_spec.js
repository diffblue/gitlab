import { GlPopover, GlProgressBar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EpicItemTimeline from 'ee/roadmap/components/epic_item_timeline.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { mockTimeframeInitialDate, mockFormattedEpic } from 'ee_jest/roadmap/mock_data';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  epic = mockFormattedEpic,
  presetType = PRESET_TYPES.MONTHS,
  timeframe = mockTimeframeMonths,
  timeframeItem = mockTimeframeMonths[0],
  timeframeString = '',
} = {}) => {
  return shallowMount(EpicItemTimeline, {
    propsData: {
      epic,
      startDate: epic.originalStartDate,
      endDate: epic.originalEndDate,
      presetType,
      timeframe,
      timeframeItem,
      timeframeString,
    },
  });
};

const getEpicBar = (wrapper) => wrapper.find('.epic-bar');

describe('EpicItemTimelineComponent', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('epic bar', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('shows the title', () => {
      expect(getEpicBar(wrapper).text()).toContain(mockFormattedEpic.title);
    });

    it('shows the progress bar with correct value', () => {
      expect(wrapper.find(GlProgressBar).attributes('value')).toBe('60');
    });

    it('shows the percentage', () => {
      expect(getEpicBar(wrapper).text()).toContain('60%');
    });

    it('contains a link to the epic', () => {
      expect(getEpicBar(wrapper).attributes('href')).toBe(mockFormattedEpic.webUrl);
    });
  });

  describe('popover', () => {
    it('shows the start and end dates', () => {
      wrapper = createComponent();

      expect(wrapper.find(GlPopover).text()).toContain('Jun 26, 2017 – Mar 10, 2018');
    });

    it('shows the weight completed', () => {
      wrapper = createComponent();

      expect(wrapper.find(GlPopover).text()).toContain('3 of 5 weight completed');
    });

    it('shows the weight completed with no numbers when there is no weights information', () => {
      wrapper = createComponent({
        epic: {
          ...mockFormattedEpic,
          descendantWeightSum: undefined,
        },
      });

      expect(wrapper.find(GlPopover).text()).toContain('- of - weight completed');
    });
  });
});
