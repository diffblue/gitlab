<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { SCAN_CADENCE_OPTIONS } from 'ee/on_demand_scans_form/settings';
import { fromGraphQLCadence } from 'ee/on_demand_scans_form/utils';
import { stripTimezoneFromISODate } from '~/lib/utils/datetime/date_format_utility';
import { sprintf } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['timezones'],
  props: {
    schedule: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    isScheduled() {
      return Boolean(this.schedule?.active);
    },
    cadence() {
      return fromGraphQLCadence(this.schedule.cadence);
    },
    cadenceOption() {
      return SCAN_CADENCE_OPTIONS.find((option) => option.value === this.cadence);
    },
    isRepeating() {
      return this.isScheduled && this.cadence;
    },
    timezone() {
      const { timezone } = this.schedule;
      return this.timezones.find(({ identifier }) => identifier === timezone) ?? {};
    },
    runDate() {
      return new Date(stripTimezoneFromISODate(this.schedule.startsAt));
    },
    text() {
      if (this.isRepeating) {
        return this.cadenceOption.text;
      }
      return this.runDate.toLocaleDateString(window.navigator.language, {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });
    },
    tooltip() {
      const time = this.runDate.toLocaleTimeString(window.navigator.language, {
        hour: '2-digit',
        minute: '2-digit',
      });
      const { abbr: timezone = '' } = this.timezone;
      if (this.isRepeating) {
        const { text, dayFormat } = this.cadenceOption.description;
        const day = dayFormat
          ? this.runDate.toLocaleDateString(window.navigator.language, dayFormat)
          : null;
        return sprintf(text, {
          day,
          time,
          timezone,
        });
      }
      return `${time} ${timezone}`;
    },
  },
};
</script>

<template>
  <span v-if="!isScheduled">-</span>
  <span v-else v-gl-tooltip="tooltip">{{ text }}</span>
</template>
