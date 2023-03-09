import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import EpicItemTimelineComponent from 'ee/roadmap/components/epic_item_timeline.vue';
import { DATE_RANGES, PRESET_TYPES, PROGRESS_WEIGHT } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate, mockEpic } from 'ee_jest/roadmap/mock_data';

Vue.use(Vuex);

const mockTimeframeWeeks = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
  presetType: PRESET_TYPES.WEEKS,
  initialDate: mockTimeframeInitialDate,
});

describe('WeeksPresetMixin', () => {
  let wrapper;

  const createComponent = ({
    presetType = PRESET_TYPES.WEEKS,
    timeframe = mockTimeframeWeeks,
    timeframeItem = mockTimeframeWeeks[0],
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
    describe('hasStartDateForWeek', () => {
      it('returns true when Epic.startDate falls within timeframeItem', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeWeeks[1] },
          timeframeItem: mockTimeframeWeeks[1],
        });

        expect(wrapper.vm.hasStartDateForWeek(mockTimeframeWeeks[1])).toBe(true);
      });

      it('returns false when Epic.startDate does not fall within timeframeItem', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeWeeks[0] },
          timeframeItem: mockTimeframeWeeks[1],
        });

        expect(wrapper.vm.hasStartDateForWeek(mockTimeframeWeeks[1])).toBe(false);
      });
    });

    describe('getLastDayOfWeek', () => {
      it('returns date object set to last day of the week from provided timeframeItem', () => {
        wrapper = createComponent();
        const lastDayOfWeek = wrapper.vm.getLastDayOfWeek(mockTimeframeWeeks[0]);

        expect(lastDayOfWeek.getDate()).toBe(6);
        expect(lastDayOfWeek.getMonth()).toBe(0);
        expect(lastDayOfWeek.getFullYear()).toBe(2018);
      });
    });

    describe('isTimeframeUnderEndDateForWeek', () => {
      const timeframeItem = new Date(2018, 0, 7); // Jan 7, 2018

      beforeEach(() => {
        wrapper = createComponent();
      });

      it('returns true if provided timeframeItem is under epicEndDate', () => {
        const epicEndDate = new Date(2018, 0, 3); // Jan 3, 2018
        /*
          Visual illustration of the example spec:

          - Each item in mockTimeframeWeeks represents a week.
            For example, the item 2017-12-17 represents -
            the timeframe representing the week starting on Dec 17, 2017

          mockTimeframeWeeks =
          [
            2017-12-17, <- the epic starting on Jan 3, 2018 is in this timeframe
            2017-12-24,
            2017-12-31, <- the epic ending on Jan 15, 2018 is in this timeframe.
            2018-01-07, <- the provided timeframeItem (Jan 7, 2018) points to this timeframe.
            ...
          ]
        */

        wrapper = createComponent({
          epic: { ...mockEpic, endDate: epicEndDate },
        });

        expect(wrapper.vm.isTimeframeUnderEndDateForWeek(timeframeItem)).toBe(true);
      });

      it('returns false if provided timeframeItem is NOT under epicEndDate', () => {
        const epicEndDate = new Date(2018, 0, 15); // Jan 15, 2018
        /*
          Visual illustration of the example spec:

          mockTimeframeWeeks =
          [
            2017-12-17, <- the epic starting on Jan 3, 2018 is in this timeframe
            2017-12-24,
            2017-12-31,
            2018-01-07, <- the provided timeframeItem (Jan 7, 2018) points to this timeframe.
            2018-01-14, <- the epic ending on Jan 15, 2018 is in this timeframe.
            ...
          ]
        */

        wrapper = createComponent({
          epic: { ...mockEpic, endDate: epicEndDate },
        });

        expect(wrapper.vm.isTimeframeUnderEndDateForWeek(timeframeItem)).toBe(false);
      });
    });

    describe('getBarWidthForSingleWeek', () => {
      it('returns calculated bar width based on provided cellWidth and day of week', () => {
        wrapper = createComponent();

        expect(Math.floor(wrapper.vm.getBarWidthForSingleWeek(300, 1))).toBe(42); // 10% size
        expect(Math.floor(wrapper.vm.getBarWidthForSingleWeek(300, 3))).toBe(128); // 50% size
        expect(wrapper.vm.getBarWidthForSingleWeek(300, 7)).toBe(300); // Full size
      });
    });

    describe('getTimelineBarStartOffsetForWeeks', () => {
      it('returns empty string when Epic startDate is out of range', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDateOutOfRange: true },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForWeeks(wrapper.vm.epic)).toBe('');
      });

      it('returns empty string when Epic startDate is undefined and endDate is out of range', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDateUndefined: true, endDateOutOfRange: true },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForWeeks(wrapper.vm.epic)).toBe('');
      });

      it('return `left: 0;` when Epic startDate is first day of the week', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: mockTimeframeWeeks[0] },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForWeeks(wrapper.vm.epic)).toBe('left: 0;');
      });

      it('returns proportional `left` value based on Epic startDate and days in the week', () => {
        wrapper = createComponent({
          epic: { ...mockEpic, startDate: new Date(2018, 0, 15) },
        });

        expect(wrapper.vm.getTimelineBarStartOffsetForWeeks(wrapper.vm.epic)).toContain('left: 38');
      });
    });

    describe('getTimelineBarWidthForWeeks', () => {
      it('returns calculated width value based on Epic.startDate and Epic.endDate', () => {
        wrapper = createComponent({
          timeframeItem: mockTimeframeWeeks[2],
          epic: {
            ...mockEpic,
            startDate: new Date(2018, 0, 1), // Jan 1, 2018
            endDate: new Date(2018, 1, 2), // Feb 2, 2018
          },
        });

        /*
          Visual illustration of the example spec:

          - Each timeframe is 180px wide.
          - The timebar width should be approximately 540px + 154.3px + 154.3px or 849px.
          - In the below, [2017-12-31] is understood as a timeframe that covers -
            the week starting on Dec 31, 2017 (ending on Jan 6, 2018).

          mockTimeframeWeeks =
             Epic start date                                  Epic end date
             Jan 1, 2018                                      Feb 2, 2018
               .                                                   .
               .                                                   .
          [ [2017-12-31][2018-01-07][2018-01-14][2018-01-21][2018-01-28] ]
               <--------------- timeline bar width ---------------->
               <--   --><---- 180px * 3 frames = 540px ----><--  -->
                  ^                                             ^
             approximately 154px                                ^
                                                        ~ approximately 154px
        */
        const expectedTimelineBarWidth = 462; // in px;

        expect(Math.floor(wrapper.vm.getTimelineBarWidthForWeeks())).toBe(expectedTimelineBarWidth);
      });
    });
  });
});
