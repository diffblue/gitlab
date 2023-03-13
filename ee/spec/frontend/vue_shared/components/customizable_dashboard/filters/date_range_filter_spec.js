import { GlDaterangePicker, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DateRangeFilter from 'ee/vue_shared/components/customizable_dashboard/filters/date_range_filter.vue';
import {
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_OPTION_INDEX,
  TODAY,
  I18N_DATE_RANGE_FILTER_TOOLTIP,
  I18N_DATE_RANGE_FILTER_TO,
  I18N_DATE_RANGE_FILTER_FROM,
} from 'ee/vue_shared/components/customizable_dashboard/filters/constants';
import { dateRangeOptionToFilter } from 'ee/vue_shared/components/customizable_dashboard/utils';

describe('DateRangeFilter', () => {
  let wrapper;

  const dateRangeOptionIndex = DATE_RANGE_OPTIONS.findIndex(
    (option) => !option.showDateRangePicker,
  );
  const customRangeOptionIndex = DATE_RANGE_OPTIONS.findIndex(
    (option) => option.showDateRangePicker,
  );

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DateRangeFilter, {
      propsData: {
        ...props,
      },
    });
  };

  const findDateRangePicker = () => wrapper.findComponent(GlDaterangePicker);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders a dropdown with the text set to the default selected option', () => {
      expect(findDropdown().props().text).toBe(
        DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX].text,
      );
    });

    it('renders a dropdown item for each option', () => {
      DATE_RANGE_OPTIONS.forEach((option, idx) => {
        expect(findDropdownItems().at(idx).text()).toBe(option.text);
      });
    });

    it('emits the selected date range when a dropdown item with a date range is clicked', () => {
      findDropdownItems().at(dateRangeOptionIndex).vm.$emit('click');

      expect(wrapper.emitted('change')).toStrictEqual([
        [dateRangeOptionToFilter(DATE_RANGE_OPTIONS[dateRangeOptionIndex])],
      ]);
    });
  });

  describe('with a default option', () => {
    const customOption = DATE_RANGE_OPTIONS[customRangeOptionIndex];

    beforeEach(() => {
      createWrapper({ defaultOption: customOption.key });
    });

    it('selects the provided default option', () => {
      expect(findDropdown().props().text).toBe(customOption.text);
    });
  });

  describe('date range picker', () => {
    describe('by default', () => {
      const { startDate, endDate } = DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX];

      beforeEach(() => {
        createWrapper({ startDate, endDate });
      });

      it('does not emit a new date range when the option shows the date range picker', async () => {
        await findDropdownItems().at(customRangeOptionIndex).vm.$emit('click');

        expect(wrapper.emitted('change')).toBeUndefined();
      });

      it('shows the date range picker with the provided date range when the option enables it', async () => {
        expect(findDateRangePicker().exists()).toBe(false);

        await findDropdownItems().at(customRangeOptionIndex).vm.$emit('click');

        expect(findDateRangePicker().props()).toMatchObject({
          toLabel: I18N_DATE_RANGE_FILTER_TO,
          fromLabel: I18N_DATE_RANGE_FILTER_FROM,
          tooltip: null,
          defaultMaxDate: TODAY,
          maxDateRange: 0,
          value: {
            startDate,
            endDate,
          },
          defaultStartDate: startDate,
          defaultEndDate: endDate,
        });
      });
    });

    describe.each([0, 12, 31])('when given a date range limit of %d', (dateRangeLimit) => {
      beforeEach(() => {
        createWrapper({ dateRangeLimit });
      });

      it('shows the date range picker with date range limit applied', async () => {
        expect(findDateRangePicker().exists()).toBe(false);

        await findDropdownItems().at(customRangeOptionIndex).vm.$emit('click');

        expect(findDateRangePicker().props()).toMatchObject({
          tooltip: dateRangeLimit ? I18N_DATE_RANGE_FILTER_TOOLTIP(dateRangeLimit) : null,
          maxDateRange: dateRangeLimit,
        });
      });
    });
  });
});
