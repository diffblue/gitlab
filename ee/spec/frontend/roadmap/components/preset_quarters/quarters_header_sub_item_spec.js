import Vue from 'vue';

import QuartersHeaderSubItemComponent from 'ee/roadmap/components/preset_quarters/quarters_header_sub_item.vue';
import { PRESET_TYPES, DATE_RANGES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import mountComponent from 'helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  currentDate = mockTimeframeQuarters[0].range[1],
  timeframeItem = mockTimeframeQuarters[0],
}) => {
  const Component = Vue.extend(QuartersHeaderSubItemComponent);

  return mountComponent(Component, {
    currentDate,
    timeframeItem,
  });
};

describe('QuartersHeaderSubItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('initializes `presetType` and `indicatorStyles` data props', () => {
      vm = createComponent({});

      expect(vm.presetType).toBe(PRESET_TYPES.QUARTERS);
      expect(vm.indicatorStyle).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('quarterBeginDate', () => {
      it('returns first month from the `timeframeItem.range`', () => {
        vm = createComponent({});

        expect(vm.quarterBeginDate).toBe(mockTimeframeQuarters[0].range[0]);
      });
    });

    describe('quarterEndDate', () => {
      it('returns first month from the `timeframeItem.range`', () => {
        vm = createComponent({});

        expect(vm.quarterEndDate).toBe(mockTimeframeQuarters[0].range[2]);
      });
    });

    describe('headerSubItems', () => {
      it('returns array of dates containing Months from timeframeItem', () => {
        vm = createComponent({});

        expect(Array.isArray(vm.headerSubItems)).toBe(true);
        vm.headerSubItems.forEach((subItem) => {
          expect(subItem instanceof Date).toBe(true);
        });
      });
    });
  });

  describe('methods', () => {
    describe('getSubItemValueClass', () => {
      it('returns string containing `label-dark` when provided subItem is greater than current date', () => {
        vm = createComponent({
          currentDate: new Date(2018, 0, 1), // Jan 1, 2018
        });
        const subItem = new Date(2018, 1, 15); // Feb 15, 2018

        expect(vm.getSubItemValueClass(subItem)).toBe('label-dark');
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
      expect(vm.$el.querySelector('.current-day-indicator-header.preset-quarters')).not.toBeNull();
    });
  });
});
