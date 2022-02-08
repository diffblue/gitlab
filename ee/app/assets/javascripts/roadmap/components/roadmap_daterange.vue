<script>
import { GlFormGroup, GlFormRadioGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

import { __, s__ } from '~/locale';

import { PRESET_TYPES, DATE_RANGES } from '../constants';
import { getPresetTypeForTimeframeRangeType } from '../utils/roadmap_utils';

export default {
  availableDateRanges: [
    { text: s__('GroupRoadmap|This quarter'), value: DATE_RANGES.CURRENT_QUARTER },
    { text: s__('GroupRoadmap|This year'), value: DATE_RANGES.CURRENT_YEAR },
    { text: s__('GroupRoadmap|Within 3 years'), value: DATE_RANGES.THREE_YEARS },
  ],
  components: {
    GlFormGroup,
    GlFormRadioGroup,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    timeframeRangeType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedDaterange: this.timeframeRangeType,
    };
  },
  computed: {
    ...mapState(['presetType']),
    daterangeDropdownText() {
      switch (this.selectedDaterange) {
        case DATE_RANGES.CURRENT_QUARTER:
          return s__('GroupRoadmap|This quarter');
        case DATE_RANGES.CURRENT_YEAR:
          return s__('GroupRoadmap|This year');
        case DATE_RANGES.THREE_YEARS:
          return s__('GroupRoadmap|Within 3 years');
        default:
          return '';
      }
    },
    availablePresets() {
      const quarters = { text: __('By quarter'), value: PRESET_TYPES.QUARTERS };
      const months = { text: __('By month'), value: PRESET_TYPES.MONTHS };
      const weeks = { text: __('By week'), value: PRESET_TYPES.WEEKS };

      if (this.selectedDaterange === DATE_RANGES.CURRENT_YEAR) {
        return [months, weeks];
      } else if (this.selectedDaterange === DATE_RANGES.THREE_YEARS) {
        return [quarters, months, weeks];
      }
      return [];
    },
  },
  methods: {
    ...mapActions(['setDaterange', 'fetchEpics', 'fetchMilestones']),
    handleDaterangeSelect(value) {
      this.selectedDaterange = value;
    },
    handleDaterangeDropdownOpen() {
      this.initialSelectedDaterange = this.selectedDaterange;
    },
    handleDaterangeDropdownClose() {
      if (this.initialSelectedDaterange !== this.selectedDaterange) {
        this.setDaterange({
          timeframeRangeType: this.selectedDaterange,
          presetType: getPresetTypeForTimeframeRangeType(this.selectedDaterange),
        });
        this.fetchEpics();
        this.fetchMilestones();
      }
    },
    handleRoadmapLayoutChange(presetType) {
      if (presetType !== this.presetType) {
        this.setDaterange({ timeframeRangeType: this.selectedDaterange, presetType });
        this.fetchEpics();
      }
    },
  },
  i18n: {
    header: __('Date range'),
  },
};
</script>

<template>
  <div>
    <label for="roadmap-daterange" class="gl-display-block">{{ $options.i18n.header }}</label>
    <gl-dropdown
      id="roadmap-daterange"
      icon="calendar"
      class="roadmap-daterange-dropdown"
      toggle-class="gl-rounded-base!"
      :text="daterangeDropdownText"
      data-testid="daterange-dropdown"
      @show="handleDaterangeDropdownOpen"
      @hide="handleDaterangeDropdownClose"
    >
      <gl-dropdown-item
        v-for="dateRange in $options.availableDateRanges"
        :key="dateRange.value"
        :value="dateRange.value"
        @click="handleDaterangeSelect(dateRange.value)"
      >
        {{ dateRange.text }}
      </gl-dropdown-item>
    </gl-dropdown>
    <gl-form-group v-if="availablePresets.length" class="gl-mb-0 gl-mt-3">
      <gl-form-radio-group
        data-testid="daterange-presets"
        :checked="presetType"
        stacked
        :options="availablePresets"
        @input="handleRoadmapLayoutChange"
      />
    </gl-form-group>
  </div>
</template>
