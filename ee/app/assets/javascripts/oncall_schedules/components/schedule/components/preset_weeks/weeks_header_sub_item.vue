<script>
import { PRESET_TYPES } from 'ee/oncall_schedules/constants';
import CommonMixin from 'ee/oncall_schedules/mixins/common_mixin';

export default {
  PRESET_TYPES,
  mixins: [CommonMixin],
  props: {
    timeframeItem: {
      type: Date,
      required: true,
    },
  },
  computed: {
    headerSubItems() {
      const timeframeItem = new Date(this.timeframeItem.getTime());
      const headerSubItems = new Array(7)
        .fill()
        .map(
          (val, i) =>
            new Date(
              timeframeItem.getFullYear(),
              timeframeItem.getMonth(),
              timeframeItem.getDate() + i,
            ),
        );

      return headerSubItems;
    },
  },
  methods: {
    getSubItemValueClass(subItem) {
      // Show dark color text only for the current date
      if (subItem.getTime() === this.$options.currentDate.getTime()) {
        return 'gl-text-gray-900! gl-font-weight-bold';
      }

      return '';
    },
    getSubItemValue(subItem) {
      return subItem.getDate();
    },
  },
};
</script>

<template>
  <div
    class="item-sublabel week-item-sublabel gl-pb-3 gl-relative gl-display-flex"
    data-testid="week-item-sublabel"
  >
    <span
      v-for="(subItem, index) in headerSubItems"
      :key="index"
      ref="weeklyDayCell"
      :class="getSubItemValueClass(subItem)"
      class="sublabel-value gl-text-gray-700 gl-font-weight-normal gl-text-center gl-flex-grow-1 gl-flex-basis-0"
      data-testid="sublabel-value"
      >{{ getSubItemValue(subItem) }}</span
    >
    <span
      v-if="hasToday"
      :style="getIndicatorStyles($options.PRESET_TYPES.WEEKS, timeframeItem)"
      class="current-day-indicator-header preset-weeks gl-absolute gl-bottom-0 gl-rounded-full gl-bg-red-500"
    ></span>
  </div>
</template>
