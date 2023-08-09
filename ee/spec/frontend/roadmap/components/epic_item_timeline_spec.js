import { GlIcon, GlPopover, GlProgressBar } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import EpicItemTimeline from 'ee/roadmap/components/epic_item_timeline.vue';
import { DATE_RANGES, PRESET_TYPES, PROGRESS_COUNT, PROGRESS_WEIGHT } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { mockTimeframeInitialDate, mockFormattedEpic, mockEpic } from 'ee_jest/roadmap/mock_data';

Vue.use(Vuex);

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  epic = mockFormattedEpic,
  presetType = PRESET_TYPES.MONTHS,
  timeframe = mockTimeframeMonths,
  timeframeItem = mockTimeframeMonths[0],
  timeframeString = '',
  progressTracking = PROGRESS_WEIGHT,
  isProgressTrackingActive = true,
  startDate,
  endDate,
} = {}) => {
  const store = createStore();

  store.dispatch('setInitialData', {
    progressTracking,
    isProgressTrackingActive,
  });

  return shallowMount(EpicItemTimeline, {
    store,
    propsData: {
      epic,
      startDate: startDate || epic.originalStartDate,
      endDate: endDate || epic.originalEndDate,
      presetType,
      timeframe,
      timeframeItem,
      timeframeString,
    },
  });
};

const getEpicBar = (wrapper) => wrapper.find('.epic-bar');

describe('EpicItemTimelineComponent', () => {
  let wrapper;

  describe('epic bar', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has correct root element classes', () => {
      expect(wrapper.classes()).toEqual(['gl-relative', 'gl-w-full']);
    });

    it('shows the title', () => {
      expect(getEpicBar(wrapper).text()).toContain(mockFormattedEpic.title);
    });

    it('shows the progress bar with correct value', () => {
      expect(wrapper.findComponent(GlProgressBar).attributes('value')).toBe('60');
    });

    it('shows the percentage', () => {
      expect(getEpicBar(wrapper).text()).toContain('60%');
    });

    it('contains a link to the epic', () => {
      expect(getEpicBar(wrapper).attributes('href')).toBe(mockFormattedEpic.webUrl);
    });

    it.each`
      isProgressTrackingActive
      ${true}
      ${false}
    `('displays tracking depending on isProgressTrackingActive', ({ isProgressTrackingActive }) => {
      wrapper = createComponent({ isProgressTrackingActive });

      expect(wrapper.findComponent(GlProgressBar).exists()).toBe(isProgressTrackingActive);
    });

    it.each`
      progressTracking   | icon
      ${PROGRESS_WEIGHT} | ${'weight'}
      ${PROGRESS_COUNT}  | ${'issue-closed'}
    `(
      'displays icon $icon when progressTracking equals $progressTracking',
      ({ progressTracking, icon }) => {
        wrapper = createComponent({ progressTracking });

        expect(wrapper.findComponent(GlIcon).props('name')).toBe(icon);
      },
    );
  });

  describe('popover', () => {
    it('shows the start and end dates', () => {
      wrapper = createComponent();

      expect(wrapper.findComponent(GlPopover).text()).toContain('Jun 26, 2017 – Mar 10, 2018');
    });

    it.each`
      progressTracking   | option      | text
      ${PROGRESS_WEIGHT} | ${'weight'} | ${'3 of 5 weight completed'}
      ${PROGRESS_COUNT}  | ${'issues'} | ${'3 of 5 issues closed'}
    `(
      'shows $option completed when progressTracking equals $progressTracking',
      ({ progressTracking, text }) => {
        wrapper = createComponent({ progressTracking });

        expect(wrapper.findComponent(GlPopover).text()).toContain(text);
      },
    );

    it.each`
      progressTracking   | option      | text
      ${PROGRESS_WEIGHT} | ${'weight'} | ${'- of - weight completed'}
      ${PROGRESS_COUNT}  | ${'issues'} | ${'- of - issues closed'}
    `(
      'shows $option completed with no numbers when there is no $option information and progressTracking equals $progressTracking',
      ({ progressTracking, text }) => {
        wrapper = createComponent({
          progressTracking,
          epic: {
            ...mockFormattedEpic,
            descendantWeightSum: undefined,
            descendantCounts: undefined,
          },
        });

        expect(wrapper.findComponent(GlPopover).text()).toContain(text);
      },
    );
  });

  describe.each`
    firstDayName  | firstDayOfWeek | timeframeItem           | expectedLeftOffset
    ${'Saturday'} | ${6}           | ${new Date(2023, 4, 6)} | ${'left: 0px;'}
    ${'Sunday'}   | ${0}           | ${new Date(2023, 4, 7)} | ${'left: 141.42'}
    ${'Monday'}   | ${1}           | ${new Date(2023, 4, 8)} | ${'left: 115.71'}
  `(
    'with first day of week set to $firstDayName for presetType WEEKS',
    ({ firstDayOfWeek, timeframeItem, expectedLeftOffset }) => {
      useFakeDate(timeframeItem);

      beforeEach(() => {
        window.gon.first_day_of_week = firstDayOfWeek;
        const mockTimeframeWeeks = getTimeframeForRangeType({
          timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
          presetType: PRESET_TYPES.WEEKS,
          initialDate: mockTimeframeInitialDate,
        });

        wrapper = createComponent({
          epic: mockEpic,
          startDate: mockEpic.startDate,
          endDate: mockEpic.endDate,
          presetType: PRESET_TYPES.WEEKS,
          timeframe: mockTimeframeWeeks,
          timeframeItem,
        });
      });

      it('sets indicator style containing accurate value of left', () => {
        expect(getEpicBar(wrapper).attributes('style')).toContain(expectedLeftOffset);
      });
    },
  );
});
