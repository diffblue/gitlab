<script>
import { GlDaterangePicker, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import {
  TODAY,
  MAX_DATE_RANGE,
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_OPTION_INDEX,
  DATE_RANGE_FILTER_I18N,
} from './constants';

export default {
  name: 'DateRangeFilter',
  components: {
    GlDaterangePicker,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
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
  },
  data() {
    return {
      selectedOption: DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX],
    };
  },
  computed: {
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.$emit('change', { startDate, endDate });
      },
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
  DATE_RANGE_FILTER_I18N,
  DATE_RANGE_OPTIONS,
  MAX_DATE_RANGE,
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
      :max-date-range="$options.MAX_DATE_RANGE"
      :to-label="$options.DATE_RANGE_FILTER_I18N.to"
      :from-label="$options.DATE_RANGE_FILTER_I18N.from"
      :tooltip="$options.DATE_RANGE_FILTER_I18N.tooltip"
      same-day-selection
    />
  </div>
</template>
