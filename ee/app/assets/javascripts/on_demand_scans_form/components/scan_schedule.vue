<script>
import { GlDatepicker, GlFormGroup, GlToggle } from '@gitlab/ui';
import { s__ } from '~/locale';
import DropdownInput from 'ee/security_configuration/components/dropdown_input.vue';
import {
  dateAndTimeToISOString,
  stripTimezoneFromISODate,
  dateToTimeInputValue,
} from '~/lib/utils/datetime/date_format_utility';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import { SCAN_CADENCE_OPTIONS } from '../settings';
import { toGraphQLCadence, fromGraphQLCadence } from '../utils';

export default {
  name: 'ScanSchedule',
  i18n: {
    scanScheduleToggleText: s__('OnDemandScans|Enable scan schedule'),
    scanStartTimeLabel: s__('OnDemandScans|Start time'),
    scanScheduleRepeatLabel: s__('OnDemandScans|at'),
    scanScheduleRepeatDefaultLabel: s__('OnDemandScans|Repeats'),
    scanScheduleTimezoneLabel: s__('OnDemandScans|Timezone'),
  },
  components: {
    GlDatepicker,
    GlToggle,
    GlFormGroup,
    DropdownInput,
    TimezoneDropdown,
  },
  inject: ['timezones'],
  props: {
    value: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      form: {
        isScheduledScan: this.value?.active ?? false,
        selectedTimezone: this.value?.timezone ?? null,
        startDate: null,
        startTime: null,
        cadence: fromGraphQLCadence(this.value?.cadence),
      },
    };
  },
  computed: {
    timezone: {
      set(timezone) {
        this.form.selectedTimezone = timezone.identifier;
      },
      get() {
        return this.selectedTimezoneData?.name ?? '';
      },
    },
    selectedTimezoneData() {
      return this.form.selectedTimezone
        ? this.timezones.find(({ identifier }) => identifier === this.form.selectedTimezone)
        : null;
    },
  },
  created() {
    const date = this.value?.startsAt ?? null;
    if (date !== null) {
      const localeDate = new Date(
        stripTimezoneFromISODate(date, this.selectedTimezoneData?.offset),
      );
      this.form.startDate = localeDate;
      this.form.startTime = date ? dateToTimeInputValue(localeDate) : null;
    }
  },
  methods: {
    handleInput() {
      const { startDate, startTime, cadence } = this.form;
      let startsAt;
      try {
        startsAt = dateAndTimeToISOString(
          startDate,
          startTime,
          this.selectedTimezoneData?.formatted_offset,
        );
      } catch (e) {
        startsAt = null;
      }
      const input = {
        active: this.form.isScheduledScan,
        startsAt,
        cadence: toGraphQLCadence(cadence),
        timezone: this.selectedTimezoneData?.identifier ?? null,
      };
      this.$emit('input', input);
    },
  },
  SCAN_CADENCE_OPTIONS,
};
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-6">
      <gl-toggle
        v-model="form.isScheduledScan"
        class="gl-mb-3"
        :label="$options.i18n.scanScheduleToggleText"
        @change="handleInput"
      />
      <transition name="fade">
        <gl-form-group v-if="form.isScheduledScan" data-testid="profile-schedule-form-group">
          <div class="gl-font-weight-bold gl-mb-3">
            {{ $options.i18n.scanStartTimeLabel }}
          </div>
          <div class="gl-display-flex gl-align-items-center gl-mb-5">
            <gl-datepicker v-model="form.startDate" @input="handleInput" />
            <span class="gl-px-3">
              {{ $options.i18n.scanScheduleRepeatLabel }}
            </span>
            <input
              v-model="form.startTime"
              type="time"
              class="gl-form-input form-control"
              @input="handleInput"
            />
          </div>

          <div class="gl-font-weight-bold gl-mb-3">
            {{ $options.i18n.scanScheduleTimezoneLabel }}
          </div>

          <timezone-dropdown
            v-model="timezone"
            :timezone-data="timezones"
            :disabled="!form.isScheduledScan"
            @input="handleInput"
          />

          <dropdown-input
            v-model="form.cadence"
            :label="$options.i18n.scanScheduleRepeatDefaultLabel"
            :default-text="$options.i18n.scanScheduleRepeatDefaultLabel"
            :options="$options.SCAN_CADENCE_OPTIONS"
            :disabled="!form.isScheduledScan"
            field="repeat-input"
            data-testid="schedule-cadence-input"
            @input="handleInput"
          />
        </gl-form-group>
      </transition>
    </div>
  </div>
</template>
