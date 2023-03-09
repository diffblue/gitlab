import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import EpicItemTimelineComponent from 'ee/roadmap/components/epic_item_timeline.vue';
import { DATE_RANGES, PRESET_TYPES, PROGRESS_WEIGHT } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate, mockEpic } from 'ee_jest/roadmap/mock_data';

Vue.use(Vuex);

const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});

describe('QuartersPresetMixin', () => {
  let wrapper;

  const createComponent = ({
    presetType = PRESET_TYPES.QUARTERS,
    timeframe = mockTimeframeQuarters,
    timeframeItem = mockTimeframeQuarters[0],
    epic = mockEpic,
  } = {}) => {
    const store = createStore();

    store.dispatch('setInitialData', {
      progressTracking: PROGRESS_WEIGHT,
    });

    return shallowMount(EpicItemTimelineComponent, {
      store,
      propsData: {
        presetType,
        timeframe,
        timeframeItem,
        epic,
        startDate: epic.startDate,
        endDate: epic.endDate,
      },
    });
  };

  describe('methods', () => {
    describe('hasStartDateForQuarter', () => {
      it('returns true when Epic.startDate falls within timeframeItem', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeQuarters[1].range[0] },
          timeframeItem: mockTimeframeQuarters[1],
        });

        expect(wrapper.vm.hasStartDateForQuarter(mockTimeframeQuarters[1])).toBe(true);
      });

      it('returns false when Epic.startDate does not fall within timeframeItem', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeQuarters[0].range[0] },
          timeframeItem: mockTimeframeQuarters[1],
        });

        expect(wrapper.vm.hasStartDateForQuarter(mockTimeframeQuarters[1])).toBe(false);
      });
    });

    describe('isTimeframeUnderEndDateForQuarter', () => {
      const timeframeItem = mockTimeframeQuarters[1];

      beforeEach(() => {
        wrapper = createComponent({});
      });

      it('returns true if provided timeframeItem is under epicEndDate', () => {
        const epicEndDate = mockTimeframeQuarters[1].range[2];

        wrapper = createComponent({
          epic: { ...mockEpic, endDate: epicEndDate },
        });

        expect(wrapper.vm.isTimeframeUnderEndDateForQuarter(timeframeItem)).toBe(true);
      });

      it('returns false if provided timeframeItem is NOT under epicEndDate', () => {
        const epicEndDate = mockTimeframeQuarters[2].range[1];

        wrapper = createComponent({
          epic: { ...mockEpic, endDate: epicEndDate },
        });

        expect(wrapper.vm.isTimeframeUnderEndDateForQuarter(timeframeItem)).toBe(false);
      });
    });

    describe('getBarWidthForSingleQuarter', () => {
      it('returns calculated bar width based on provided cellWidth, daysInQuarter and day of quarter', () => {
        wrapper = createComponent();

        expect(Math.floor(wrapper.vm.getBarWidthForSingleQuarter(300, 91, 1))).toBe(3); // 10% size
        expect(Math.floor(wrapper.vm.getBarWidthForSingleQuarter(300, 91, 45))).toBe(148); // 50% size
        expect(wrapper.vm.getBarWidthForSingleQuarter(300, 91, 91)).toBe(300); // Full size
      });
    });

    describe('getTimelineBarStartOffsetForQuarters', () => {
      it('returns empty string when Epic startDate is out of range', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDateOutOfRange: true },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForQuarters(wrapper.vm.epic)).toBe('');
      });

      it('returns empty string when Epic startDate is undefined and endDate is out of range', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDateUndefined: true, endDateOutOfRange: true },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForQuarters(wrapper.vm.epic)).toBe('');
      });

      it('return `left: 0;` when Epic startDate is first day of the quarter', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeQuarters[0].range[0] },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForQuarters(wrapper.vm.epic)).toBe('left: 0;');
      });

      it('returns proportional `left` value based on Epic startDate and days in the quarter', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeQuarters[0].range[1] },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForQuarters(wrapper.vm.epic)).toContain(
          'left: 34',
        );
      });
    });

    describe('getTimelineBarWidthForQuarters', () => {
      it('returns calculated width value based on Epic.startDate and Epic.endDate', () => {
        wrapper = createComponent({
          timeframeItem: mockTimeframeQuarters[0],
          epic: {
            ...mockEpic,
            startDate: mockTimeframeQuarters[0].range[1],
            endDate: mockTimeframeQuarters[1].range[1],
          },
        });

        expect(Math.floor(wrapper.vm.getTimelineBarWidthForQuarters(wrapper.vm.epic))).toBe(180);
      });
    });
  });
});
