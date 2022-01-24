import Vue, { nextTick } from 'vue';

import QuartersHeaderItemComponent from 'ee/roadmap/components/preset_quarters/quarters_header_item.vue';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeIndex = 0;
const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  timeframeIndex = mockTimeframeIndex,
  timeframeItem = mockTimeframeQuarters[mockTimeframeIndex],
  timeframe = mockTimeframeQuarters,
}) => {
  const Component = Vue.extend(QuartersHeaderItemComponent);

  return mountComponent(Component, {
    timeframeIndex,
    timeframeItem,
    timeframe,
  });
};

describe('QuartersHeaderItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});
      const currentDate = new Date();

      expect(vm.currentDate.getDate()).toBe(currentDate.getDate());
    });
  });

  describe('computed', () => {
    describe('quarterBeginDate', () => {
      it('returns date object representing quarter begin date for current `timeframeItem`', () => {
        expect(vm.quarterBeginDate).toBe(mockTimeframeQuarters[mockTimeframeIndex].range[0]);
      });
    });

    describe('quarterEndDate', () => {
      it('returns date object representing quarter end date for current `timeframeItem`', () => {
        expect(vm.quarterEndDate).toBe(mockTimeframeQuarters[mockTimeframeIndex].range[2]);
      });
    });

    describe('timelineHeaderLabel', () => {
      it('returns string containing Year and Quarter for current timeline header item', () => {
        vm = createComponent({});

        expect(vm.$el.innerText.trim()).toContain('2016 Q3');
      });

      it('returns string containing only Quarter for current timeline header item when previous header contained Year', () => {
        vm = createComponent({
          timeframeIndex: mockTimeframeIndex + 2,
          timeframeItem: mockTimeframeQuarters[mockTimeframeIndex + 2],
        });

        expect(vm.$el.innerText.trim()).toContain('2017 Q1');
      });
    });

    describe('timelineHeaderClass', () => {
      it('returns empty string when timeframeItem quarter is less than current quarter', () => {
        vm = createComponent({});

        expect(vm.timelineHeaderClass).toBe('');
      });

      it('returns string containing `label-dark label-bold` when current quarter is same as timeframeItem quarter', async () => {
        vm = createComponent({
          timeframeItem: mockTimeframeQuarters[1],
        });

        [, vm.currentDate] = mockTimeframeQuarters[1].range;
        await nextTick();
        expect(vm.timelineHeaderClass).toBe('label-dark label-bold');
      });

      it('returns string containing `label-dark` when current quarter is less than timeframeItem quarter', () => {
        const timeframeIndex = 2;
        const timeframeItem = mockTimeframeQuarters[1];
        vm = createComponent({
          timeframeIndex,
          timeframeItem,
        });

        [vm.currentDate] = mockTimeframeQuarters[0].range;

        expect(vm.timelineHeaderClass).toBe('label-dark');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `timeline-header-item`', () => {
      expect(vm.$el.classList.contains('timeline-header-item')).toBeTruthy();
    });

    it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
      const itemLabelEl = vm.$el.querySelector('.item-label');

      expect(itemLabelEl).not.toBeNull();
      expect(itemLabelEl.innerText.trim()).toBe('2016 Q3');
    });
  });
});
