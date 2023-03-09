import { mount } from '@vue/test-utils';

import WeeksHeaderSubItemComponent from 'ee/roadmap/components/preset_weeks/weeks_header_sub_item.vue';
import { PRESET_TYPES, DATE_RANGES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeWeeks = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
  presetType: PRESET_TYPES.WEEKS,
  initialDate: mockTimeframeInitialDate,
});

describe('MonthsHeaderSubItemComponent', () => {
  let wrapper;

  const createComponent = ({
    currentDate = mockTimeframeWeeks[0],
    timeframeItem = mockTimeframeWeeks[0],
  } = {}) => {
    wrapper = mount(WeeksHeaderSubItemComponent, {
      propsData: {
        currentDate,
        timeframeItem,
      },
    });
  };

  describe('header subitems', () => {
    it('is array of dates containing days of week from timeframeItem', () => {
      createComponent();

      expect(wrapper.findAll('.sublabel-value').wrappers.map((w) => w.text())).toStrictEqual([
        '31',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
      ]);
    });
  });

  describe('subitem value class', () => {
    it('adds  `label-dark` class for dates which are greater than current week day', () => {
      createComponent({
        currentDate: new Date(2018, 0, 1), // Jan 1, 2018
      });

      expect(
        wrapper.findAll('.sublabel-value.label-dark').wrappers.map((w) => w.text()),
      ).toStrictEqual(['1', '2', '3', '4', '5', '6']);
    });

    it('adds `label-dark label-bold` classes for date which is same as current week day', () => {
      createComponent({
        currentDate: new Date(2018, 0, 1), // Jan 1, 2018
      });

      expect(
        wrapper.findAll('.sublabel-value.label-dark.label-bold').wrappers.map((w) => w.text()),
      ).toStrictEqual(['1']);
    });
  });

  it('renders component container element with class `item-sublabel`', () => {
    createComponent();

    expect(wrapper.classes()).toContain('item-sublabel');
  });

  it('renders sub item element with class `sublabel-value`', () => {
    createComponent();

    expect(wrapper.find('.sublabel-value').exists()).toBe(true);
  });

  it('renders element with class `current-day-indicator-header` when hasToday is true', () => {
    createComponent();

    expect(wrapper.find('.current-day-indicator-header.preset-weeks').exists()).toBe(true);
  });
});
