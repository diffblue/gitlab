<script>
import { PRESET_TYPES } from '../../../constants';
import CommonMixin from '../../../mixins/common_mixin';

export default {
  mixins: [CommonMixin],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
    timelineWidth: {
      type: Number,
      required: false,
      default: 1,
    },
  },
  computed: {
    isVisible() {
      switch (this.presetType) {
        case PRESET_TYPES.WEEKS:
          return this.hasToday;
        case PRESET_TYPES.DAYS:
          return this.isToday;
        default:
          return false;
      }
    },
  },
};
</script>

<template>
  <span
    v-if="isVisible"
    :style="getIndicatorStyles(presetType, timeframeItem, timelineWidth)"
    data-testid="current-day-indicator"
    class="current-day-indicator gl-absolute gl-bg-red-500 gl-pointer-events-none gl-translate-x-n50"
  ></span>
</template>
