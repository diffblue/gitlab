import { mount } from '@vue/test-utils';

import MonthsHeaderSubItemComponent from 'ee/roadmap/components/preset_months/months_header_sub_item.vue';
import { PRESET_TYPES, DATE_RANGES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

describe('MonthsHeaderSubItemComponent', () => {
  let wrapper;

  const createComponent = ({
    currentDate = mockTimeframeMonths[0],
    timeframeItem = mockTimeframeMonths[0],
  } = {}) => {
    wrapper = mount(MonthsHeaderSubItemComponent, {
      propsData: {
        currentDate,
        timeframeItem,
      },
    });
  };

  describe('header sub items', () => {
    it('lists dates containing Sundays from timeframeItem', () => {
      createComponent();
      expect(wrapper.findAll('.sublabel-value').wrappers.map((w) => w.text())).toStrictEqual([
        '7',
        '14',
        '21',
        '28',
      ]);
    });
  });

  describe('header sub item class', () => {
    it('includes `label-dark` when timeframe year and month are greater than current year and month', () => {
      createComponent();

      expect(wrapper.classes()).toContain('label-dark');
    });

    it('does not include `label-dark` when timeframe year and month are less than current year and month', () => {
      createComponent({
        currentDate: new Date(2017, 10, 1), // Nov 1, 2017
        timeframeItem: new Date(2018, 0, 1), // Jan 1, 2018
      });

      expect(wrapper.classes()).not.toContain('label-dark');
    });
  });

  describe('sub item value class', () => {
    it('includes `label-dark` for items greater than current date', () => {
      createComponent({
        currentDate: new Date(2018, 0, 21), // Jan 21, 2018
      });

      expect(
        wrapper.findAll('.sublabel-value.label-dark').wrappers.map((w) => w.text()),
      ).toStrictEqual(['21', '28']);
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

  it('renders element with class `current-day-indicator-header` when it includes today', () => {
    createComponent();

    expect(wrapper.find('.current-day-indicator-header.preset-months').exists()).toBe(true);
  });
});
