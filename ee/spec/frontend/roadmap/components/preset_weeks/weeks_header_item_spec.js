import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import WeeksHeaderItemComponent from 'ee/roadmap/components/preset_weeks/weeks_header_item.vue';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';

import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeIndex = 0;
const mockTimeframeWeeks = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
  presetType: PRESET_TYPES.WEEKS,
  initialDate: mockTimeframeInitialDate,
});

describe('WeeksHeaderItemComponent', () => {
  let wrapper;

  const createComponent = ({
    timeframeIndex = mockTimeframeIndex,
    timeframeItem = mockTimeframeWeeks[mockTimeframeIndex],
    timeframe = mockTimeframeWeeks,
  } = {}) => {
    wrapper = mount(WeeksHeaderItemComponent, {
      propsData: {
        timeframeIndex,
        timeframeItem,
        timeframe,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('timeline header label', () => {
    it('is string containing Year, Month and Date for first timeframe item of the entire timeframe', () => {
      createComponent({});

      expect(wrapper.text()).toContain('2017 Dec 31');
    });

    it('returns string containing Year, Month and Date for timeframe item when it is first week of the year', () => {
      createComponent({
        timeframeIndex: 3,
        timeframeItem: new Date(2019, 0, 6),
      });

      expect(wrapper.text()).toContain('2019 Jan 6');
    });

    it('returns string containing only Month and Date timeframe item when it is somewhere in the middle of timeframe', () => {
      createComponent({
        timeframeIndex: mockTimeframeIndex + 2,
        timeframeItem: mockTimeframeWeeks[mockTimeframeIndex + 2],
      });

      expect(wrapper.text()).toContain('Jan 14');
    });
  });

  describe('timeline header class', () => {
    it('does not include `label-dark label-bold` when timeframeItem week is less than current week', () => {
      createComponent();

      expect(wrapper.find('.item-label').classes()).not.toContain('label-dark');
      expect(wrapper.find('.item-label').classes()).not.toContain('label-bold');
    });

    it('returns string containing `label-dark label-bold` when current week is same as timeframeItem week', async () => {
      createComponent({});
      wrapper.vm.currentDate = mockTimeframeWeeks[mockTimeframeIndex];
      await nextTick();

      expect(wrapper.find('.item-label').classes()).toContain('label-dark');
      expect(wrapper.find('.item-label').classes()).toContain('label-bold');
    });

    it('returns string containing `label-dark` when current week is less than timeframeItem week', async () => {
      const timeframeIndex = 2;
      const timeframeItem = mockTimeframeWeeks[timeframeIndex];
      createComponent({
        timeframeIndex,
        timeframeItem,
      });

      [wrapper.vm.currentDate] = mockTimeframeWeeks;
      await nextTick();

      expect(wrapper.find('.item-label').classes()).toContain('label-dark');
      expect(wrapper.find('.item-label').classes()).not.toContain('label-bold');
    });
  });

  it('renders component container element with class `timeline-header-item`', () => {
    createComponent();

    expect(wrapper.classes()).toContain('timeline-header-item');
  });

  it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
    createComponent();
    const itemLabelEl = wrapper.find('.item-label');

    expect(itemLabelEl.exists()).toBe(true);
    expect(itemLabelEl.text()).toBe('2017 Dec 31');
  });
});
