import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';

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

  afterEach(() => {
    wrapper.destroy();
  });

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
    const findTimelineHeader = () => wrapper.find('.item-label');

    it('does not include `label-dark label-bold` is less than current quarter', () => {
      createComponent();

      expect(findTimelineHeader().classes()).not.toContain('label-dark');
      expect(findTimelineHeader().classes()).not.toContain('label-bold');
    });

    it('includes `label-dark label-bold` when current quarter is same as timeframeItem quarter', async () => {
      createComponent({
        timeframeItem: mockTimeframeQuarters[1],
      });

      [, wrapper.vm.currentDate] = mockTimeframeQuarters[1].range;
      await nextTick();

      expect(findTimelineHeader().classes()).toContain('label-dark');
      expect(findTimelineHeader().classes()).toContain('label-bold');
    });

    it('includes `label-dark` when current quarter is less than timeframeItem quarter', async () => {
      const timeframeIndex = 2;
      const timeframeItem = mockTimeframeQuarters[1];
      createComponent({
        timeframeIndex,
        timeframeItem,
      });

      [wrapper.vm.currentDate] = mockTimeframeQuarters[0].range;
      await nextTick();

      expect(findTimelineHeader().classes()).toContain('label-dark');
      expect(findTimelineHeader().classes()).not.toContain('label-bold');
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
    expect(itemLabelEl.text()).toBe('2016 Q3');
  });
});
