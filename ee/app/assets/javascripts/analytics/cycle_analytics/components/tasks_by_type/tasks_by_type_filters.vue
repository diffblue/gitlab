<script>
import { GlDropdown, GlDropdownItem, GlSegmentedControl, GlIcon } from '@gitlab/ui';
import { TASKS_BY_TYPE_FILTERS, TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS } from '../../constants';

export default {
  name: 'TasksByTypeFilters',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSegmentedControl,
    GlIcon,
  },
  props: {
    subjectFilter: {
      type: String,
      required: true,
    },
  },
  computed: {
    subjectFilterOptions() {
      return Object.entries(TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS).map(([value, text]) => ({
        text,
        value,
      }));
    },
  },
  TASKS_BY_TYPE_FILTERS,
};
</script>
<template>
  <div class="js-tasks-by-type-chart-filters">
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
  </div>
</template>
