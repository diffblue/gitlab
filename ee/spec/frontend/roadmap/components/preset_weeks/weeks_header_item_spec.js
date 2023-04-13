import { mount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
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

  const findItemLabel = () => wrapper.find('.item-label');

  describe('timeline header label', () => {
    it('contains Year, Month and Date for first timeframe item of the entire timeframe', () => {
      createComponent({});

      expect(wrapper.text()).toContain('2017 Dec 31');
    });

    it('contains Year, Month and Date for timeframe item when it is first week of the year', () => {
      createComponent({
        timeframeIndex: 3,
        timeframeItem: new Date(2019, 0, 6),
      });

      expect(wrapper.text()).toContain('2019 Jan 6');
    });

    it('contains only Month and Date for timeframe item when it is somewhere in the middle of timeframe', () => {
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

      expect(findItemLabel().classes('label-dark')).toBe(false);
      expect(findItemLabel().classes('label-bold')).toBe(false);
    });

    describe('when current week is the same as timeframeItem week', () => {
      useFakeDate(mockTimeframeWeeks[mockTimeframeIndex]);

      it('returns string containing `label-dark label-bold`', () => {
        createComponent({});

        expect(findItemLabel().classes('label-dark')).toBe(true);
        expect(findItemLabel().classes('label-bold')).toBe(true);
      });
    });

    describe('when the current week is less than timeframeItem week', () => {
      useFakeDate(mockTimeframeWeeks[0]);

      it('returns string containing `label-dark`', () => {
        const timeframeIndex = 2;
        const timeframeItem = mockTimeframeWeeks[timeframeIndex];
        createComponent({
          timeframeIndex,
          timeframeItem,
        });

        expect(findItemLabel().classes('label-dark')).toBe(true);
        expect(findItemLabel().classes('label-bold')).toBe(false);
      });
    });
  });

  it('renders component container element with class `timeline-header-item`', () => {
    createComponent();

    expect(wrapper.classes('timeline-header-item')).toBe(true);
  });

  it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
    createComponent();

    expect(findItemLabel().exists()).toBe(true);
    expect(findItemLabel().text()).toBe('2017 Dec 31');
  });
});
