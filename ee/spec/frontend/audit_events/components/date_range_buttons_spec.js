import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DateRangeButtons from 'ee/audit_events/components/date_range_buttons.vue';
import { CURRENT_DATE, SAME_DAY_OFFSET } from 'ee/audit_events/constants';
import { getDateInPast, dateAtFirstDayOfMonth } from '~/lib/utils/datetime_utility';

describe('DateRangeButtons component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(DateRangeButtons, {
        propsData: { ...props },
      }),
    );
  };

  const findButtons = (f) => wrapper.findAllComponents(GlButton).filter(f);
  const findSelectedButtons = () => findButtons((b) => b.props('selected'));
  const findOneWeekAgoButton = () => wrapper.findByTestId('date_range_button_last_7_days');
  const findTwoWeeksAgoButton = () => wrapper.findByTestId('date_range_button_last_14_days');
  const findThisMonthButton = () => wrapper.findByTestId('date_range_button_this_month');

  describe('when the last 7 days is selected', () => {
    beforeEach(() => {
      createComponent({
        dateRange: {
          startDate: getDateInPast(CURRENT_DATE, 7 - SAME_DAY_OFFSET),
          endDate: CURRENT_DATE,
        },
      });
    });

    describe.each`
      button                   | selected | text              | trackingLabel                       | startDate
      ${findOneWeekAgoButton}  | ${true}  | ${'Last 7 days'}  | ${'date_range_button_last_7_days'}  | ${getDateInPast(CURRENT_DATE, 7 - SAME_DAY_OFFSET)}
      ${findTwoWeeksAgoButton} | ${false} | ${'Last 14 days'} | ${'date_range_button_last_14_days'} | ${getDateInPast(CURRENT_DATE, 14 - SAME_DAY_OFFSET)}
      ${findThisMonthButton}   | ${false} | ${'This month'}   | ${'date_range_button_this_month'}   | ${dateAtFirstDayOfMonth(CURRENT_DATE)}
    `('for the "$text" button', ({ button, selected, text, trackingLabel, startDate }) => {
      it(`the button is ${selected ? 'selected' : 'not selected'}`, () => {
        expect(button().props('selected')).toBe(selected);
      });

      it('shows the correct text', () => {
        expect(button().text()).toBe(text);
      });

      it('sets the correct tracking data', () => {
        expect(button().attributes()).toMatchObject({
          'data-track-action': 'click_date_range_button',
          'data-track-label': trackingLabel,
        });
      });

      it('emits an "input" event with the dateRange when a new date range is selected', () => {
        button().vm.$emit('click');

        expect(wrapper.emitted('input')).toEqual([[{ startDate, endDate: CURRENT_DATE }]]);
      });
    });
  });

  describe('when no predefined date range is selected', () => {
    beforeEach(() => {
      createComponent({
        dateRange: {
          startDate: getDateInPast(CURRENT_DATE, 5),
          endDate: getDateInPast(CURRENT_DATE, 2),
        },
      });
    });

    it('shows that no button is selected', () => {
      expect(findSelectedButtons()).toHaveLength(0);
    });
  });
});
