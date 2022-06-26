<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlSegmentedControl,
  GlIcon,
  GlSprintf,
} from '@gitlab/ui';
import { removeFlash } from '~/analytics/shared/utils';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import {
  TASKS_BY_TYPE_FILTERS,
  TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS,
  TASKS_BY_TYPE_MAX_LABELS,
} from '../../constants';
import LabelsSelector from '../labels_selector.vue';

export default {
  name: 'TasksByTypeFilters',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSegmentedControl,
    GlDropdownDivider,
    GlIcon,
    LabelsSelector,
    GlSprintf,
  },
  props: {
    selectedLabelIds: {
      type: Array,
      required: true,
    },
    maxLabels: {
      type: Number,
      required: false,
      default: TASKS_BY_TYPE_MAX_LABELS,
    },
    subjectFilter: {
      type: String,
      required: true,
    },
    defaultGroupLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    subjectFilterOptions() {
      return Object.entries(TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS).map(([value, text]) => ({
        text,
        value,
      }));
    },
    selectedLabelsCount() {
      return this.selectedLabelIds.length;
    },
    maxLabelsSelected() {
      return this.selectedLabelIds.length >= this.maxLabels;
    },
  },
  methods: {
    canUpdateLabelFilters(value) {
      // we can always remove a filter
      return this.selectedLabelIds.includes(value) || !this.maxLabelsSelected;
    },
    // TODO: not sure if we still need this
    handleLabelSelected(value) {
      removeFlash('notice');
      if (this.canUpdateLabelFilters(value)) {
        this.$emit('update-filter', { filter: TASKS_BY_TYPE_FILTERS.LABEL, value });
      } else {
        const { maxLabels } = this;
        const message = sprintf(
          s__('CycleAnalytics|Only %{maxLabels} labels can be selected at this time'),
          { maxLabels },
        );
        createFlash({
          message,
          type: 'notice',
        });
      }
    },
  },
  TASKS_BY_TYPE_FILTERS,
};
</script>
<template>
  <div class="js-tasks-by-type-chart-filters">
    <!-- TODO: replace label selector with GlDropdown -->
    <!-- <labels-selector
      data-testid="type-of-work-filters-label"
      :initial-data="defaultGroupLabels"
      :max-labels="maxLabels"
      :aria-label="__('CycleAnalytics|Display chart filters')"
      :selected-label-ids="selectedLabelIds"
      aria-expanded="false"
      multiselect
      right
      @select-label="handleLabelSelected"
    > -->
    <gl-dropdown icon="settings" text="Settings" :text-sr-only="true" right no-caret>
      <template #button-text>
        <gl-icon class="vertical-align-top" name="settings" />
        <gl-icon name="chevron-down" />
      </template>
      <gl-dropdown-item class="gl-m-0 gl-p-0">
        <div class="gl-mb-5 gl-px-5">
          <p class="gl-font-weight-bold gl-text-left gl-mb-3">{{ s__('CycleAnalytics|Show') }}</p>
          <gl-segmented-control
            data-testid="type-of-work-filters-subject"
            :checked="subjectFilter"
            :options="subjectFilterOptions"
            @input="
              (value) =>
                $emit('update-filter', { filter: $options.TASKS_BY_TYPE_FILTERS.SUBJECT, value })
            "
          />
        </div>
      </gl-dropdown-item>
    </gl-dropdown>
    <!-- </labels-selector> -->
  </div>
</template>
