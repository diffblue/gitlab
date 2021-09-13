<script>
import { GlCard, GlDatepicker, GlFormCheckbox, GlFormGroup } from '@gitlab/ui';
import DropdownInput from 'ee/security_configuration/components/dropdown_input.vue';
import {
  dateAndTimeToISOString,
  stripTimezoneFromISODate,
  dateToTimeInputValue,
} from '~/lib/utils/datetime/date_format_utility';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown.vue';
import { SCAN_CADENCE_OPTIONS } from '../settings';
import { toGraphQLCadence, fromGraphQLCadence } from '../utils';

export default {
  name: 'ScanSchedule',
  components: {
    GlCard,
    GlDatepicker,
    GlFormCheckbox,
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
  <gl-card class="gl-bg-gray-10">
    <div class="row">
      <div class="col-12 col-md-6">
        <gl-form-checkbox v-model="form.isScheduledScan" class="gl-mb-3" @input="handleInput">
          <span class="gl-font-weight-bold">{{ s__('OnDemandScans|Schedule scan') }}</span>
        </gl-form-checkbox>
        <gl-form-group
          class="gl-pl-6"
          data-testid="profile-schedule-form-group"
          :disabled="!form.isScheduledScan"
        >
          <div class="gl-font-weight-bold gl-mb-3">
            {{ s__('OnDemandScans|Start time') }}
          </div>
          <timezone-dropdown
            v-model="timezone"
            :timezone-data="timezones"
            :disabled="!form.isScheduledScan"
            @input="handleInput"
          />
          <div class="gl-display-flex gl-align-items-center">
            <gl-datepicker v-model="form.startDate" @input="handleInput" />
            <span class="gl-px-3">
              {{ __('at') }}
            </span>
            <input
              v-model="form.startTime"
              type="time"
              class="gl-form-input form-control"
              @input="handleInput"
            />
          </div>
          <dropdown-input
            v-model="form.cadence"
            :label="__('Repeats')"
            :default-text="__('Repeats')"
            :options="$options.SCAN_CADENCE_OPTIONS"
            :disabled="!form.isScheduledScan"
            field="repeat-input"
            class="gl-mt-5"
            data-testid="schedule-cadence-input"
            @input="handleInput"
          />
        </gl-form-group>
      </div>
    </div>
  </gl-card>
</template>
