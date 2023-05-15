<script>
import { PRESET_TYPES, HOURS_IN_DAY } from 'ee/oncall_schedules/constants';
import CommonMixin from 'ee/oncall_schedules/mixins/common_mixin';

export default {
  PRESET_TYPES,
  HOURS_IN_DAY,
  mixins: [CommonMixin],
  props: {
    timeframeItem: {
      type: Date,
      required: true,
    },
  },
  methods: {
    getSubItemValueClass(hour) {
      // Show dark color text only for the current hour
      const currentDate = new Date();
      if (hour - 1 !== currentDate.getHours()) {
        return '';
      }

      return 'gl-text-gray-900! gl-font-weight-bold';
    },
  },
};
</script>

<template>
  <div class="item-sublabel gl-pb-3 gl-relative gl-display-flex" data-testid="day-item-sublabel">
    <span
      v-for="hour in $options.HOURS_IN_DAY"
      :key="hour"
      ref="dailyHourCell"
      :class="getSubItemValueClass(hour)"
      class="sublabel-value gl-text-gray-700 gl-font-weight-normal gl-text-center gl-flex-grow-1 gl-flex-basis-0"
      data-testid="sublabel-value"
      >{{ hour - 1 }}</span
    >
    <span
      v-if="isToday"
      :style="getIndicatorStyles($options.PRESET_TYPES.DAYS)"
      class="current-day-indicator-header preset-days gl-absolute gl-bottom-0 gl-rounded-full gl-bg-red-500"
      data-testid="day-item-sublabel-current-indicator"
    ></span>
  </div>
</template>
