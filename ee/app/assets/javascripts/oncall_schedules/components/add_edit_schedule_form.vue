<script>
import { GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { isEqual, isEmpty } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, __ } from '~/locale';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';

export const i18n = {
  selectTimezone: s__('OnCallSchedules|Select timezone'),
  search: __('Search'),
  fields: {
    name: {
      title: __('Name'),
      validation: {
        empty: __("Can't be empty"),
      },
    },
    description: { title: __('Description (optional)') },
    timezone: {
      title: __('Timezone'),
      description: s__(
        'OnCallSchedules|Sets the default timezone for the schedule, for all participants',
      ),
      validation: {
        empty: __("Can't be empty"),
      },
    },
  },
  errorMsg: s__('OnCallSchedules|Failed to add schedule'),
};

export default {
  i18n,
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    TimezoneDropdown,
  },
  directives: {
    SafeHtml,
  },
  inject: ['projectPath', 'timezones'],
  props: {
    form: {
      type: Object,
      required: true,
    },
    validationState: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      tzSearchTerm: '',
      selectedDropdownTimezone: null,
    };
  },
  computed: {
    selectedTimezone() {
      return isEmpty(this.form.timezone) ? i18n.selectTimezone : this.form.timezone.identifier;
    },
  },
  methods: {
    isTimezoneSelected(tz) {
      return isEqual(tz, this.form.timezone);
    },
    setTimezone(selectedTz) {
      this.$emit('update-schedule-form', { type: 'timezone', value: selectedTz });
      this.selectedDropdownTimezone = selectedTz;
    },
  },
};
</script>

<template>
  <gl-form>
    <gl-form-group
      :label="$options.i18n.fields.name.title"
      :invalid-feedback="$options.i18n.fields.name.validation.empty"
      label-size="sm"
      label-for="schedule-name"
      :state="validationState.name"
      required
    >
      <gl-form-input
        id="schedule-name"
        data-testid="schedule-name-field"
        :value="form.name"
        @blur="$emit('update-schedule-form', { type: 'name', value: $event.target.value })"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.fields.description.title"
      label-size="sm"
      label-for="schedule-description"
    >
      <gl-form-input
        id="schedule-description"
        :value="form.description"
        @blur="$emit('update-schedule-form', { type: 'description', value: $event.target.value })"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.fields.timezone.title"
      label-size="sm"
      label-for="schedule-timezone"
      :description="$options.i18n.fields.timezone.description"
      :state="validationState.timezone"
      :invalid-feedback="$options.i18n.fields.timezone.validation.empty"
      data-testid="schedule-timezone-container"
      required
    >
      <timezone-dropdown
        id="schedule-timezone"
        :value="selectedTimezone"
        :timezone-data="timezones"
        :additional-class="[{ 'invalid-dropdown': !validationState.timezone }]"
        name="schedule-timezone"
        @input="setTimezone"
      />
    </gl-form-group>
  </gl-form>
</template>
