import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import EpicItemTimelineComponent from 'ee/roadmap/components/epic_item_timeline.vue';
import { DATE_RANGES, PRESET_TYPES, PROGRESS_WEIGHT } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate, mockEpic } from 'ee_jest/roadmap/mock_data';

Vue.use(Vuex);

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

describe('MonthsPresetMixin', () => {
  let wrapper;

  const createComponent = ({
    presetType = PRESET_TYPES.MONTHS,
    timeframe = mockTimeframeMonths,
    timeframeItem = mockTimeframeMonths[0],
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
    describe('hasStartDateForMonth', () => {
      it('returns true when Epic.startDate falls within timeframeItem', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeMonths[1] },
          timeframeItem: mockTimeframeMonths[1],
        });

        expect(wrapper.vm.hasStartDateForMonth(mockTimeframeMonths[1])).toBe(true);
      });

      it('returns false when Epic.startDate does not fall within timeframeItem', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeMonths[0] },
          timeframeItem: mockTimeframeMonths[1],
        });

        expect(wrapper.vm.hasStartDateForMonth(mockTimeframeMonths[1])).toBe(false);
      });
    });

    describe('isTimeframeUnderEndDateForMonth', () => {
      const timeframeItem = new Date(2018, 0, 10); // Jan 10, 2018

      it('returns true if provided timeframeItem is under epicEndDate', () => {
        const epicEndDate = new Date(2018, 0, 26); // Jan 26, 2018

        wrapper = createComponent({
          epic: { ...mockEpic, endDate: epicEndDate },
        });

        expect(wrapper.vm.isTimeframeUnderEndDateForMonth(timeframeItem)).toBe(true);
      });

      it('returns false if provided timeframeItem is NOT under epicEndDate', () => {
        const epicEndDate = new Date(2018, 1, 26); // Feb 26, 2018

        wrapper = createComponent({
          epic: { ...mockEpic, endDate: epicEndDate },
        });

        expect(wrapper.vm.isTimeframeUnderEndDateForMonth(timeframeItem)).toBe(false);
      });
    });

    describe('getBarWidthForSingleMonth', () => {
      it('returns calculated bar width based on provided cellWidth, daysInMonth and date', () => {
        wrapper = createComponent();

        expect(wrapper.vm.getBarWidthForSingleMonth(300, 30, 1)).toBe(10); // 10% size
        expect(wrapper.vm.getBarWidthForSingleMonth(300, 30, 15)).toBe(150); // 50% size
        expect(wrapper.vm.getBarWidthForSingleMonth(300, 30, 30)).toBe(300); // Full size
      });
    });

    describe('getTimelineBarStartOffsetForMonths', () => {
      it('returns empty string when Epic startDate is out of range', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDateOutOfRange: true },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForMonths(wrapper.vm.epic)).toBe('');
      });

      it('returns empty string when Epic startDate is undefined and endDate is out of range', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDateUndefined: true, endDateOutOfRange: true },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForMonths(wrapper.vm.epic)).toBe('');
      });

      it('return `left: 0;` when Epic startDate is first day of the month', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: new Date(2018, 0, 1) },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForMonths(wrapper.vm.epic)).toBe('left: 0;');
      });

      it('returns proportional `left` value based on Epic startDate and days in the month', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: new Date(2018, 0, 15) }, // Jan 15, 2018
        });

        const startDateValue = 15;
        const totalDaysInJanuary = 31;
        const expectedLeftOffset = Math.floor((startDateValue / totalDaysInJanuary) * 100); // Approx. 48%
        expect(wrapper.vm.getTimelineBarStartOffsetForMonths(wrapper.vm.epic)).toContain(
          `left: ${expectedLeftOffset}%`,
        );
      });
    });

    describe('getTimelineBarWidthForMonths', () => {
      it('returns calculated width value based on Epic.startDate and Epic.endDate', () => {
        wrapper = createComponent({
          timeframeItem: mockTimeframeMonths[0],
          epic: {
            ...mockEpic,
            startDate: new Date(2018, 0, 1), // Jan 01, 2018
            endDate: new Date(2018, 2, 15), // Mar 15, 2018
          },
        });

        /*
          The epic timeline bar width calculation:

           Jan: 31 days                       = 180px
         + Feb: 28 days                       = 180px
         + Mar: (180px / 31 days)  * 15 days ~= 87.15px
         ---------------------------------------------------
                                     Total   ~= 447px
        */
        const expectedTimelineBarWidth = 447; // in px.
        expect(Math.floor(wrapper.vm.getTimelineBarWidthForMonths())).toBe(
          expectedTimelineBarWidth,
        );
      });
    });
  });
});
