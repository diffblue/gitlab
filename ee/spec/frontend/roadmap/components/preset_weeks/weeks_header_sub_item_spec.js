import Vue from 'vue';

import WeeksHeaderSubItemComponent from 'ee/roadmap/components/preset_weeks/weeks_header_sub_item.vue';
import { PRESET_TYPES, DATE_RANGES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import mountComponent from 'helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeWeeks = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
  presetType: PRESET_TYPES.WEEKS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  currentDate = mockTimeframeWeeks[0],
  timeframeItem = mockTimeframeWeeks[0],
}) => {
  const Component = Vue.extend(WeeksHeaderSubItemComponent);

  return mountComponent(Component, {
    currentDate,
    timeframeItem,
  });
};

describe('MonthsHeaderSubItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('initializes `presetType` and `indicatorStyles` data props', () => {
      vm = createComponent({});

      expect(vm.presetType).toBe(PRESET_TYPES.WEEKS);
      expect(vm.indicatorStyle).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('headerSubItems', () => {
      it('returns `headerSubItems` array of dates containing days of week from timeframeItem', () => {
        vm = createComponent({});

        expect(Array.isArray(vm.headerSubItems)).toBe(true);
        expect(vm.headerSubItems).toHaveLength(7);
        vm.headerSubItems.forEach((subItem) => {
          expect(subItem instanceof Date).toBe(true);
        });
      });
    });
  });

  describe('methods', () => {
    describe('getSubItemValueClass', () => {
      it('returns string containing `label-dark` when provided subItem is greater than current week day', () => {
        vm = createComponent({
          currentDate: new Date(2018, 0, 1), // Jan 1, 2018
        });
        const subItem = new Date(2018, 0, 25); // Jan 25, 2018

        expect(vm.getSubItemValueClass(subItem)).toBe('label-dark');
      });

      it('returns string containing `label-dark label-bold` when provided subItem is same as current week day', () => {
        const currentDate = new Date(2018, 0, 25);
        vm = createComponent({
          currentDate,
        });
        const subItem = currentDate;

        expect(vm.getSubItemValueClass(subItem)).toBe('label-dark label-bold');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `item-sublabel`', () => {
      expect(vm.$el.classList.contains('item-sublabel')).toBe(true);
    });

    it('renders sub item element with class `sublabel-value`', () => {
      expect(vm.$el.querySelector('.sublabel-value')).not.toBeNull();
    });

    it('renders element with class `current-day-indicator-header` when hasToday is true', () => {
      expect(vm.$el.querySelector('.current-day-indicator-header.preset-weeks')).not.toBeNull();
    });
  });
});
