<script>
import {
  GlButton,
  GlFormGroup,
  GlSegmentedControl,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

import { visitUrl, mergeUrlParams, updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { EPICS_STATES, PRESET_TYPES, DATE_RANGES } from '../constants';
import EpicsFilteredSearchMixin from '../mixins/filtered_search_mixin';
import { getPresetTypeForTimeframeRangeType } from '../utils/roadmap_utils';

const pickerType = {
  Start: 'start',
  End: 'end',
};

export default {
  pickerType,
  epicStates: EPICS_STATES,
  availableDateRanges: [
    { text: s__('GroupRoadmap|This quarter'), value: DATE_RANGES.CURRENT_QUARTER },
    { text: s__('GroupRoadmap|This year'), value: DATE_RANGES.CURRENT_YEAR },
    { text: s__('GroupRoadmap|Within 3 years'), value: DATE_RANGES.THREE_YEARS },
  ],
  availableSortOptions: [
    {
      id: 1,
      title: __('Start date'),
      sortDirection: {
        descending: 'start_date_desc',
        ascending: 'start_date_asc',
      },
    },
    {
      id: 2,
      title: __('Due date'),
      sortDirection: {
        descending: 'end_date_desc',
        ascending: 'end_date_asc',
      },
    },
  ],
  components: {
    GlButton,
    GlFormGroup,
    GlSegmentedControl,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    FilteredSearchBar,
  },
  mixins: [EpicsFilteredSearchMixin, glFeatureFlagMixin()],
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
    ...mapState([
      'presetType',
      'epicsState',
      'sortedBy',
      'filterParams',
      'progressTracking',
      'isShowingMilestones',
      'milestonesType',
    ]),
    selectedEpicStateTitle() {
      if (this.epicsState === EPICS_STATES.ALL) {
        return __('All epics');
      } else if (this.epicsState === EPICS_STATES.OPENED) {
        return __('Open epics');
      }
      return __('Closed epics');
    },
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
      const quarters = { text: __('Quarters'), value: PRESET_TYPES.QUARTERS };
      const months = { text: __('Months'), value: PRESET_TYPES.MONTHS };
      const weeks = { text: __('Weeks'), value: PRESET_TYPES.WEEKS };

      if (this.selectedDaterange === DATE_RANGES.CURRENT_YEAR) {
        return [months, weeks];
      } else if (this.selectedDaterange === DATE_RANGES.THREE_YEARS) {
        return [quarters, months, weeks];
      }
      return [];
    },
  },
  watch: {
    urlParams: {
      deep: true,
      immediate: true,
      handler(params) {
        if (Object.keys(params).length) {
          updateHistory({
            url: setUrlParams(params, window.location.href, true),
            title: document.title,
            replace: true,
          });
        }
      },
    },
  },
  methods: {
    ...mapActions(['setEpicsState', 'setFilterParams', 'setSortedBy', 'fetchEpics']),
    handleDaterangeSelect(value) {
      this.selectedDaterange = value;
    },
    handleDaterangeDropdownOpen() {
      this.initialSelectedDaterange = this.selectedDaterange;
    },
    handleDaterangeDropdownClose() {
      if (this.initialSelectedDaterange !== this.selectedDaterange) {
        visitUrl(
          mergeUrlParams(
            {
              timeframe_range_type: this.selectedDaterange,
              layout: getPresetTypeForTimeframeRangeType(this.selectedDaterange),
            },
            window.location.href,
          ),
        );
      }
    },
    handleRoadmapLayoutChange(presetType) {
      visitUrl(
        mergeUrlParams(
          { timeframe_range_type: this.selectedDaterange, layout: presetType },
          window.location.href,
        ),
      );
    },
    handleEpicStateChange(epicsState) {
      this.setEpicsState(epicsState);
      this.fetchEpics();
    },
    handleFilterEpics(filters, cleared) {
      if (filters.length || cleared) {
        this.setFilterParams(this.getFilterParams(filters));
        this.fetchEpics();
      }
    },
    handleSortEpics(sortedBy) {
      this.setSortedBy(sortedBy);
      this.fetchEpics();
    },
  },
  i18n: {
    settings: __('Settings'),
  },
};
</script>

<template>
  <div class="epics-filters epics-roadmap-filters epics-roadmap-filters-gl-ui">
    <div
      class="epics-details-filters filtered-search-block gl-display-flex gl-flex-direction-column gl-xl-flex-direction-row gl-pb-3 row-content-block second-block"
    >
      <gl-dropdown
        v-if="!glFeatures.roadmapSettings"
        icon="calendar"
        class="gl-mr-0 gl-lg-mr-3 mb-sm-2 roadmap-daterange-dropdown"
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
          >{{ dateRange.text }}</gl-dropdown-item
        >
      </gl-dropdown>
      <gl-form-group
        v-if="availablePresets.length && !glFeatures.roadmapSettings"
        class="gl-mr-0 gl-lg-mr-3 mb-sm-2"
      >
        <gl-segmented-control
          :checked="presetType"
          :options="availablePresets"
          class="gl-display-flex d-xl-block"
          buttons
          @input="handleRoadmapLayoutChange"
        />
      </gl-form-group>
      <gl-dropdown
        v-if="!glFeatures.roadmapSettings"
        :text="selectedEpicStateTitle"
        class="gl-mr-0 gl-lg-mr-3 mb-sm-2 dropdown-epics-state"
        toggle-class="gl-rounded-base!"
      >
        <gl-dropdown-item
          :is-check-item="true"
          :is-checked="epicsState === $options.epicStates.ALL"
          @click="handleEpicStateChange('all')"
          >{{ __('All epics') }}</gl-dropdown-item
        >
        <gl-dropdown-divider />
        <gl-dropdown-item
          :is-check-item="true"
          :is-checked="epicsState === $options.epicStates.OPENED"
          @click="handleEpicStateChange('opened')"
          >{{ __('Open epics') }}</gl-dropdown-item
        >
        <gl-dropdown-item
          :is-check-item="true"
          :is-checked="epicsState === $options.epicStates.CLOSED"
          @click="handleEpicStateChange('closed')"
          >{{ __('Closed epics') }}</gl-dropdown-item
        >
      </gl-dropdown>
      <filtered-search-bar
        :namespace="groupFullPath"
        :search-input-placeholder="__('Search or filter results...')"
        :tokens="getFilteredSearchTokens()"
        :sort-options="$options.availableSortOptions"
        :initial-filter-value="getFilteredSearchValue()"
        :initial-sort-by="sortedBy"
        recent-searches-storage-key="epics"
        class="gl-flex-grow-1"
        @onFilter="handleFilterEpics"
        @onSort="handleSortEpics"
      />
      <gl-button
        v-if="glFeatures.roadmapSettings"
        icon="settings"
        class="gl-mb-3 gl-lg-ml-3 gl-sm-mt-3"
        :aria-label="$options.i18n.settings"
        data-testid="settings-button"
        @click="$emit('toggleSettings', $event)"
      >
        {{ $options.i18n.settings }}
      </gl-button>
    </div>
  </div>
</template>
