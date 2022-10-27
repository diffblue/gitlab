<script>
import { GlTable } from '@gitlab/ui';
import { DASHBOARD_TABLE_FIELDS } from '../constants';
import TimePeriodHeader from './time_period_header.vue';

export default {
  name: 'DoraComparisonTable',
  components: {
    GlTable,
    TimePeriodHeader,
  },
  props: {
    dateRanges: {
      type: Object,
      required: true,
    },
    data: {
      type: Array,
      required: true,
    },
  },
  fields: DASHBOARD_TABLE_FIELDS,
};
</script>
<template>
  <gl-table :fields="$options.fields" :items="data">
    <template #head(current)="{ label }">
      <time-period-header
        :name="label"
        :start-date="dateRanges.current.startDate"
        :end-date="dateRanges.current.endDate"
      />
    </template>
    <template #head(previous)="{ label }">
      <time-period-header
        :name="label"
        :start-date="dateRanges.previous.startDate"
        :end-date="dateRanges.previous.endDate"
      />
    </template>
  </gl-table>
</template>
