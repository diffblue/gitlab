<script>
import { GlDaterangePicker, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { dateRangeOptionToFilter, getDateRangeOption } from '../utils';
import {
  TODAY,
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_OPTION_INDEX,
  I18N_DATE_RANGE_FILTER_TOOLTIP,
  I18N_DATE_RANGE_FILTER_TO,
  I18N_DATE_RANGE_FILTER_FROM,
} from './constants';

export default {
  name: 'DateRangeFilter',
  components: {
    GlDaterangePicker,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    defaultOption: {
      type: String,
      required: false,
      default: DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX].key,
    },
    startDate: {
      type: Date,
      required: false,
      default: null,
    },
    endDate: {
      type: Date,
      required: false,
      default: null,
    },
    dateRangeLimit: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      selectedOption: getDateRangeOption(this.defaultOption),
    };
  },
  computed: {
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.$emit(
          'change',
          dateRangeOptionToFilter({
            ...this.selectedOption,
            startDate,
            endDate,
          }),
        );
      },
    },
    dateRangeTooltip() {
      if (this.dateRangeLimit) {
        return I18N_DATE_RANGE_FILTER_TOOLTIP(this.dateRangeLimit);
      }

      return null;
    },
  },
  methods: {
    selectOption(option) {
      this.selectedOption = option;

      const { startDate, endDate, showDateRangePicker = false } = option;

      if (!showDateRangePicker && startDate && endDate) {
        this.dateRange = { startDate, endDate };
      }

      this.showDateRangePicker = showDateRangePicker;
    },
  },
  I18N_DATE_RANGE_FILTER_TO,
  I18N_DATE_RANGE_FILTER_FROM,
  DATE_RANGE_OPTIONS,
  TODAY,
};
</script>

<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-gap-3 gl-xs-w-full"
  >
    <gl-dropdown :text="selectedOption.text">
      <gl-dropdown-item
        v-for="(option, idx) in $options.DATE_RANGE_OPTIONS"
        :key="idx"
        @click="selectOption(option)"
      >
        {{ option.text }}
      </gl-dropdown-item>
    </gl-dropdown>
    <gl-daterange-picker
      v-if="selectedOption.showDateRangePicker"
      v-model="dateRange"
      :default-start-date="dateRange.startDate"
      :default-end-date="dateRange.endDate"
      :default-max-date="$options.TODAY"
      :max-date-range="dateRangeLimit"
      :to-label="$options.I18N_DATE_RANGE_FILTER_TO"
      :from-label="$options.I18N_DATE_RANGE_FILTER_FROM"
      :tooltip="dateRangeTooltip"
      same-day-selection
    />
  </div>
</template>
