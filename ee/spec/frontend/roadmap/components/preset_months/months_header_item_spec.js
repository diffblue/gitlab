import { mount } from '@vue/test-utils';

import MonthsHeaderItemComponent from 'ee/roadmap/components/preset_months/months_header_item.vue';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';

import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const mockTimeframeIndex = 0;

describe('MonthsHeaderItemComponent', () => {
  let wrapper;

  const createComponent = ({
    timeframeIndex = mockTimeframeIndex,
    timeframeItem = mockTimeframeMonths[mockTimeframeIndex],
    timeframe = mockTimeframeMonths,
  } = {}) => {
    wrapper = mount(MonthsHeaderItemComponent, {
      propsData: {
        timeframeIndex,
        timeframeItem,
        timeframe,
      },
    });
  };

  const findTimelineHeader = () => wrapper.find('.item-label');
  describe('timeline header label', () => {
    it('is string containing Year and Month for current timeline header item', () => {
      createComponent();

      expect(findTimelineHeader().text()).toBe('2018 Jan');
    });

    it('is string containing only Month for current timeline header item when previous header contained Year', () => {
      createComponent({
        timeframeIndex: mockTimeframeIndex + 1,
        timeframeItem: mockTimeframeMonths[mockTimeframeIndex + 1],
      });

      expect(findTimelineHeader().text()).toBe('Feb');
    });
  });

  describe('timeline header class', () => {
    it('is empty string when timeframeItem year or month is less than current year or month', () => {
      createComponent();

      expect(findTimelineHeader().classes()).toStrictEqual(['item-label']);
    });

    it('includes `label-dark label-bold` when current year and month is same as timeframeItem year and month', () => {
      createComponent({
        timeframeItem: new Date(),
      });

      expect(findTimelineHeader().classes()).toHaveLength(3);
      expect(findTimelineHeader().classes()).toContain('label-dark');
      expect(findTimelineHeader().classes()).toContain('label-bold');
    });

    it('includes `label-dark` when current year and month is less than timeframeItem year and month', () => {
      const timeframeIndex = 2;
      const timeframeItem = new Date(
        mockTimeframeMonths[timeframeIndex].getFullYear(),
        mockTimeframeMonths[timeframeIndex].getMonth() + 2,
        1,
      );
      const currentYear = mockTimeframeMonths[timeframeIndex].getFullYear();
      const currentMonth = mockTimeframeMonths[timeframeIndex].getMonth() + 1;

      jest.useFakeTimers({ legacyFakeTimers: false });
      jest.setSystemTime(new Date(`${currentYear}-0${currentMonth}-01T00:00:00Z`));

      createComponent({
        timeframeIndex,
        timeframeItem,
      });

      expect(findTimelineHeader().classes()).toHaveLength(2);
      expect(findTimelineHeader().classes()).toContain('label-dark');
    });
  });

  it('renders component container element with class `timeline-header-item`', () => {
    createComponent();
    expect(wrapper.classes()).toContain('timeline-header-item');
  });

  it('renders item label element class `item-label`', () => {
    createComponent();

    const itemLabelEl = wrapper.find('.item-label');

    expect(itemLabelEl.exists()).toBe(true);
  });
});
