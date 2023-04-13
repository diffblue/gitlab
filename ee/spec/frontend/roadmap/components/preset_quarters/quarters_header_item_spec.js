import { mount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import QuartersHeaderItemComponent from 'ee/roadmap/components/preset_quarters/quarters_header_item.vue';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeIndex = 0;
const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});

describe('QuartersHeaderItemComponent', () => {
  let wrapper;

  const createComponent = ({
    timeframeIndex = mockTimeframeIndex,
    timeframeItem = mockTimeframeQuarters[mockTimeframeIndex],
    timeframe = mockTimeframeQuarters,
  } = {}) => {
    wrapper = mount(QuartersHeaderItemComponent, {
      propsData: {
        timeframeIndex,
        timeframeItem,
        timeframe,
      },
    });
  };

  const findTimelineHeader = () => wrapper.find('.item-label');

  describe('timeline header label', () => {
    it('contains Year and Quarter for current timeline header item', () => {
      createComponent({});

      expect(wrapper.text()).toContain('2016 Q3');
    });

    it('contains only Quarter for current timeline header item when previous header contained Year', () => {
      createComponent({
        timeframeIndex: mockTimeframeIndex + 2,
        timeframeItem: mockTimeframeQuarters[mockTimeframeIndex + 2],
      });

      expect(wrapper.text()).toContain('2017 Q1');
    });
  });

  describe('timeline header class', () => {
    it('does not include `label-dark label-bold` is less than current quarter', () => {
      createComponent();

      expect(findTimelineHeader().classes('label-dark')).toBe(false);
      expect(findTimelineHeader().classes('label-bold')).toBe(false);
    });

    describe('when current quarter is the same as timeframeItem quarter', () => {
      useFakeDate(mockTimeframeQuarters[1].range[1]);

      it('includes `label-dark label-bold`', () => {
        createComponent({
          timeframeItem: mockTimeframeQuarters[1],
        });

        expect(findTimelineHeader().classes('label-dark')).toBe(true);
        expect(findTimelineHeader().classes('label-bold')).toBe(true);
      });
    });

    describe('when current quarter is less than timeframeItem quarter', () => {
      useFakeDate(mockTimeframeQuarters[0].range[0]);

      it('includes `label-dark`', () => {
        const timeframeIndex = 2;
        const timeframeItem = mockTimeframeQuarters[1];
        createComponent({
          timeframeIndex,
          timeframeItem,
        });

        expect(findTimelineHeader().classes('label-dark')).toBe(true);
        expect(findTimelineHeader().classes('label-bold')).toBe(false);
      });
    });
  });

  it('renders component container element with class `timeline-header-item`', () => {
    createComponent();

    expect(wrapper.classes('timeline-header-item')).toBe(true);
  });

  it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
    createComponent();

    expect(findTimelineHeader().exists()).toBe(true);
    expect(findTimelineHeader().text()).toBe('2016 Q3');
  });
});
