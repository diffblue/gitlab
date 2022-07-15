<script>
import { GlSegmentedControl } from '@gitlab/ui';
import { TASKS_BY_TYPE_FILTERS, TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS } from '../../constants';

export default {
  name: 'TasksByTypeFilters',
  components: {
    GlSegmentedControl,
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
    <gl-segmented-control
      data-testid="type-of-work-filters-subject"
      :checked="subjectFilter"
      :options="subjectFilterOptions"
      @input="
        (value) => $emit('update-filter', { filter: $options.TASKS_BY_TYPE_FILTERS.SUBJECT, value })
      "
    />
  </div>
</template>
