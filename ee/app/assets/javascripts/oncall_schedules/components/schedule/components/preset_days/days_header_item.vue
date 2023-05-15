<script>
import { PRESET_TYPES, TIMELINE_CELL_WIDTH } from 'ee/oncall_schedules/constants';
import DaysHeaderSubItem from './days_header_sub_item.vue';

export default {
  PRESET_TYPES,
  components: {
    DaysHeaderSubItem,
  },
  props: {
    timeframeItem: {
      type: Date,
      required: true,
    },
  },
  computed: {
    timelineHeaderStyles() {
      return {
        width: `calc(${100}% - ${TIMELINE_CELL_WIDTH}px)`,
      };
    },
  },
};
</script>

<template>
  <span
    class="timeline-header-item gl-float-left"
    data-testid="timeline-header-item"
    :style="timelineHeaderStyles"
  >
    <days-header-sub-item :timeframe-item="timeframeItem" />
  </span>
</template>
