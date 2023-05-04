import { shallowMount } from '@vue/test-utils';
import CurrentDayIndicator from 'ee/oncall_schedules/components/schedule/components/current_day_indicator.vue';
import { PRESET_TYPES, HOURS_IN_DAY } from 'ee/oncall_schedules/constants';
import { useFakeDate } from 'helpers/fake_date';

describe('CurrentDayIndicator', () => {
  let wrapper;
  // January 3rd, 2018 - current date (faked)
  useFakeDate(2018, 0, 3);
  // January 1st, 2018 is the first  day of the week-long timeframe
  // so as long as current date (faked January 3rd, 2018) is within week timeframe
  // current indicator will be rendered
  const mockTimeframeInitialDate = new Date(2018, 0, 1); // Monday
  const mockCurrentDate = new Date(2018, 0, 3); // Wednesday

  function createComponent({
    props = { presetType: PRESET_TYPES.WEEKS, timeframeItem: mockTimeframeInitialDate },
  } = {}) {
    wrapper = shallowMount(CurrentDayIndicator, {
      propsData: {
        ...props,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders span element containing class `current-day-indicator`', () => {
    expect(wrapper.classes('current-day-indicator')).toBe(true);
  });

  it('sets correct styles for a week that on a different day than the timeframe start date', () => {
    /**
     * Our start date for the timeframe in this spec is a Monday,
     * and the current day is the following Wednesday.
     * This creates a gap of two days so our generated offset should represent:
     * DayDiffOffset + weeklyOffset + weeklyHourOffset
     * Note: We do not round these calculations
     * 28.571428571428573 + 0
     */
    const leftOffset = '28.571428571428573';
    expect(wrapper.attributes('style')).toBe(`left: ${leftOffset}%;`);
  });

  it('sets correct styles for a day', () => {
    createComponent({
      props: { presetType: PRESET_TYPES.DAYS, timeframeItem: mockCurrentDate },
    });
    const currentDate = new Date();
    const base = 100 / HOURS_IN_DAY;
    const hours = base * currentDate.getHours();
    const minutes = base * (currentDate.getMinutes() / 60);
    const left = hours + minutes;
    expect(wrapper.attributes('style')).toBe(`left: ${left}%;`);
  });
});
