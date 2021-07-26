<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { datesMatch, dateAtFirstDayOfMonth, getDateInPast } from '~/lib/utils/datetime_utility';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { n__, s__ } from '~/locale';
import { CURRENT_DATE } from '../constants';

const DATE_RANGE_OPTIONS = [
  {
    text: n__('Last %d day', 'Last %d days', 7),
    startDate: getDateInPast(CURRENT_DATE, 7),
    endDate: CURRENT_DATE,
  },
  {
    text: n__('Last %d day', 'Last %d days', 14),
    startDate: getDateInPast(CURRENT_DATE, 14),
    endDate: CURRENT_DATE,
  },
  {
    text: s__('AuditLogs|This month'),
    startDate: dateAtFirstDayOfMonth(CURRENT_DATE),
    endDate: CURRENT_DATE,
  },
];

export default {
  components: {
    GlButton,
    GlButtonGroup,
  },
  props: {
    dateRange: {
      type: Object,
      required: true,
    },
  },
  methods: {
    onDateRangeClicked({ startDate, endDate }) {
      this.$emit('input', { startDate, endDate });
    },
    isCurrentDateRange({ startDate, endDate }) {
      const { dateRange } = this;
      return datesMatch(startDate, dateRange.startDate) && datesMatch(endDate, dateRange.endDate);
    },
    trackingLabel({ text }) {
      return `date_range_button_${convertToSnakeCase(text)}`;
    },
  },
  DATE_RANGE_OPTIONS,
};
</script>

<template>
  <gl-button-group>
    <gl-button
      v-for="(dateRangeOption, idx) in $options.DATE_RANGE_OPTIONS"
      :key="idx"
      :selected="isCurrentDateRange(dateRangeOption)"
      data-track-action="click_date_range_button"
      :data-track-label="trackingLabel(dateRangeOption)"
      @click="onDateRangeClicked(dateRangeOption)"
      >{{ dateRangeOption.text }}</gl-button
    >
  </gl-button-group>
</template>
