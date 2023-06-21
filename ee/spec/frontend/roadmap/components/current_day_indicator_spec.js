import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import CurrentDayIndicator from 'ee/roadmap/components/current_day_indicator.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { mockTimeframeInitialDate } from 'ee_jest/roadmap/mock_data';

const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});
const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const mockTimeframeWeeks = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
  presetType: PRESET_TYPES.WEEKS,
  initialDate: mockTimeframeInitialDate,
});

describe('CurrentDayIndicator', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(CurrentDayIndicator, {
      propsData: {
        presetType: PRESET_TYPES.MONTHS,
        timeframeItem: mockTimeframeMonths[0],
        ...props,
      },
    });
  };

  const findCurrentDayIndicator = () => wrapper.find('span');
  const findCurrentDayIndicatorStyle = () =>
    findCurrentDayIndicator().element.getAttribute('style');

  useFakeDate(mockTimeframeMonths[0]);

  it('renders span element containing class `current-day-indicator`', () => {
    createComponent();

    expect(findCurrentDayIndicator().exists()).toBe(true);
    expect(findCurrentDayIndicator().classes('current-day-indicator')).toBe(true);
  });

  describe('when presetType is QUARTERS and currentDate is within current quarter', () => {
    useFakeDate(mockTimeframeQuarters[0].range[1]);

    beforeEach(() => {
      createComponent({
        presetType: PRESET_TYPES.QUARTERS,
        timeframeItem: mockTimeframeQuarters[0],
      });
    });

    it('shows current day indicator', () => {
      expect(findCurrentDayIndicator().exists()).toBe(true);
    });

    it('sets indicatorStyles containing `left` with value `34%`', () => {
      expect(findCurrentDayIndicatorStyle()).toBe('left: 34%;');
    });
  });

  describe('when presetType is MONTHS and currentDate is within current month', () => {
    useFakeDate(new Date(2020, 0, 15));

    beforeEach(() => {
      createComponent({
        presetType: PRESET_TYPES.MONTHS,
        timeframeItem: new Date(2020, 0, 1),
      });
    });

    it('shows current day indicator', () => {
      expect(findCurrentDayIndicator().exists()).toBe(true);
    });

    it('sets indicatorStyles containing `left` with value `48%`', () => {
      expect(findCurrentDayIndicatorStyle()).toBe('left: 48%;');
    });
  });

  describe('when presetType is WEEKS and currentDate is within current week', () => {
    useFakeDate(mockTimeframeWeeks[0]);

    beforeEach(() => {
      createComponent({
        presetType: PRESET_TYPES.WEEKS,
        timeframeItem: mockTimeframeWeeks[0],
      });
    });

    it('shows current day indicator', () => {
      expect(findCurrentDayIndicator().exists()).toBe(true);
    });

    it('sets indicatorStyles containing `left` with value `7%`', () => {
      expect(findCurrentDayIndicatorStyle()).toBe('left: 7%;');
    });

    describe.each`
      firstDayName  | firstDayOfWeek | timeframeItem           | expectedLeftOffset
      ${'Saturday'} | ${6}           | ${new Date(2023, 4, 6)} | ${'left: 93%;'}
      ${'Sunday'}   | ${0}           | ${new Date(2023, 4, 7)} | ${'left: 7%;'}
      ${'Monday'}   | ${1}           | ${new Date(2023, 4, 8)} | ${'left: 21%;'}
    `(
      'with first day of week set to $firstDayName',
      ({ firstDayOfWeek, timeframeItem, expectedLeftOffset }) => {
        useFakeDate(timeframeItem);
        window.gon.first_day_of_week = firstDayOfWeek;

        beforeEach(() => {
          createComponent({
            presetType: PRESET_TYPES.WEEKS,
            timeframeItem,
          });
        });

        it(`sets indicator style correctly`, () => {
          expect(findCurrentDayIndicatorStyle()).toBe(expectedLeftOffset);
        });
      },
    );
  });
});
