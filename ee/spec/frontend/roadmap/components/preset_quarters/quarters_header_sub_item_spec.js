import { mount } from '@vue/test-utils';

import QuartersHeaderSubItemComponent from 'ee/roadmap/components/preset_quarters/quarters_header_sub_item.vue';
import { PRESET_TYPES, DATE_RANGES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});

describe('QuartersHeaderSubItemComponent', () => {
  let wrapper;

  const createComponent = ({
    currentDate = mockTimeframeQuarters[0].range[1],
    timeframeItem = mockTimeframeQuarters[0],
  } = {}) => {
    wrapper = mount(QuartersHeaderSubItemComponent, {
      propsData: {
        currentDate,
        timeframeItem,
      },
    });
  };

  describe('sub items', () => {
    it('is array of dates containing Months from timeframeItem', () => {
      createComponent();

      expect(wrapper.findAll('.sublabel-value').wrappers.map((w) => w.text())).toStrictEqual([
        'Jul',
        'Aug',
        'Sep',
      ]);
    });
  });

  describe('subitem value class', () => {
    it('includes `label-dark` when provided subItem is greater than current date', () => {
      createComponent();

      expect(
        wrapper.findAll('.sublabel-value.label-dark').wrappers.map((w) => w.text()),
      ).toStrictEqual(['Aug', 'Sep']);
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

  it('renders element with class `current-day-indicator-header` for today', () => {
    createComponent();

    expect(wrapper.find('.current-day-indicator-header.preset-quarters').exists()).toBe(true);
  });
});
