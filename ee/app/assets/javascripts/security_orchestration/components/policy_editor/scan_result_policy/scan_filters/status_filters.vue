<script>
import StatusFilter from './status_filter.vue';
import { NEWLY_DETECTED, PREVIOUSLY_EXISTING } from './constants';

export default {
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  name: 'StatusFilters',
  components: {
    StatusFilter,
  },
  props: {
    selected: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    selectionDisabled() {
      return Boolean(this.selected[NEWLY_DETECTED] && this.selected[PREVIOUSLY_EXISTING]);
    },
  },
  methods: {
    isFilterSelected(filter) {
      return Boolean(this.selected[filter]);
    },
    setStatusFilter(filter) {
      const oppositeKey = filter === NEWLY_DETECTED ? PREVIOUSLY_EXISTING : NEWLY_DETECTED;

      this.$emit('input', {
        ...this.selected,
        [oppositeKey]: null,
        [filter]: [],
      });
    },
    removeFilter(filter) {
      this.$emit('remove', filter);
    },
    setStatuses(statuses, key) {
      this.$emit('input', {
        ...this.selected,
        [key]: statuses,
      });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-gap-3 gl-w-full">
    <status-filter
      v-if="isFilterSelected($options.NEWLY_DETECTED)"
      :disabled="selectionDisabled"
      :filter="$options.NEWLY_DETECTED"
      :selected="selected[$options.NEWLY_DETECTED]"
      @input="setStatuses($event, $options.NEWLY_DETECTED)"
      @change-group="setStatusFilter"
      @remove="removeFilter"
    />
    <status-filter
      v-if="isFilterSelected($options.PREVIOUSLY_EXISTING)"
      :disabled="selectionDisabled"
      :filter="$options.PREVIOUSLY_EXISTING"
      :selected="selected[$options.PREVIOUSLY_EXISTING]"
      @input="setStatuses($event, $options.PREVIOUSLY_EXISTING)"
      @change-group="setStatusFilter"
      @remove="removeFilter"
    />
  </div>
</template>
