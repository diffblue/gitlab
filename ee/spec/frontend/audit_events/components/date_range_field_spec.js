import { GlDaterangePicker } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import DateRangeButtons from 'ee/audit_events/components/date_range_buttons.vue';
import DateRangeField from 'ee/audit_events/components/date_range_field.vue';
import { CURRENT_DATE, MAX_DATE_RANGE } from 'ee/audit_events/constants';
import {
  dateAtFirstDayOfMonth,
  getDateInPast,
  parsePikadayDate,
} from '~/lib/utils/datetime_utility';

describe('DateRangeField component', () => {
  let wrapper;

  const startDate = parsePikadayDate('2020-03-13');
  const endDate = parsePikadayDate('2020-03-14');

  const findDatePicker = () => wrapper.findComponent(GlDaterangePicker);
  const findDateRangeButtons = () => wrapper.findComponent(DateRangeButtons);

  const createComponent = (props = {}, stubs = {}) => {
    wrapper = shallowMount(DateRangeField, {
      propsData: { ...props },
      stubs: { ...stubs },
    });
  };

  describe('default behaviour', () => {
    it('sets the max date range on the date picker', () => {
      createComponent();

      expect(findDatePicker().props('maxDateRange')).toBe(MAX_DATE_RANGE);
    });

    it("sets the max selectable date to today's date on the date picker", () => {
      createComponent();

      expect(findDatePicker().props('defaultMaxDate').toDateString()).toBe(
        CURRENT_DATE.toDateString(),
      );
    });

    it('sets the default start date to the start of the month', () => {
      createComponent();

      expect(findDatePicker().props('defaultStartDate').toDateString()).toBe(
        dateAtFirstDayOfMonth(CURRENT_DATE).toDateString(),
      );
    });

    it("sets the default end date to today's date", () => {
      createComponent();

      expect(findDatePicker().props('defaultEndDate').toDateString()).toBe(
        CURRENT_DATE.toDateString(),
      );
    });

    it('passes both startDate and endDate to the date picker as default dates', () => {
      createComponent({ startDate, endDate });

      expect(findDatePicker().props()).toMatchObject({
        defaultStartDate: startDate,
        defaultEndDate: endDate,
      });
    });

    it('sets the tooltip on the date picker with the max date range', () => {
      createComponent();

      expect(findDatePicker().props('tooltip')).toBe(
        `Date range limited to ${MAX_DATE_RANGE} days`,
      );
    });

    it('does not set the default min date on the date picker', () => {
      createComponent();

      expect(findDatePicker().props('defaultMinDate')).toBe(null);
    });
  });

  describe('when a only a endDate is picked', () => {
    it('emits the "selected" event with the picked endDate and startDate set to the day before', async () => {
      createComponent();
      findDatePicker().vm.$emit('input', { endDate });

      await nextTick();
      expect(wrapper.emitted().selected[0]).toEqual([
        {
          startDate: getDateInPast(endDate, 1),
          endDate,
        },
      ]);
    });
  });

  describe('when a new date range is picked', () => {
    it('emits the "selected" event with the picked startDate and endDate', async () => {
      createComponent();
      findDatePicker().vm.$emit('input', { startDate, endDate });

      await nextTick();
      expect(wrapper.emitted().selected[0]).toEqual([
        {
          startDate,
          endDate,
        },
      ]);
    });
  });

  describe('when a date range button is pressed', () => {
    it('emits the "selected" event with the picked startDate and endDate', async () => {
      createComponent();
      findDateRangeButtons().vm.$emit('input', { startDate, endDate });

      await nextTick();
      expect(wrapper.emitted().selected[0]).toEqual([
        {
          startDate,
          endDate,
        },
      ]);
    });
  });

  describe('number of days selected', () => {
    it('renders the number of days selected when there is a date range', () => {
      createComponent({ startDate, endDate }, { GlDaterangePicker });

      expect(findDatePicker().text()).toContain('2 days selected');
    });

    it('does not render the number of days selected when the date range is less than one', () => {
      createComponent({ startDate, endDate: startDate }, { GlDaterangePicker });

      expect(findDatePicker().text()).not.toContain('days selected');
    });
  });
});
