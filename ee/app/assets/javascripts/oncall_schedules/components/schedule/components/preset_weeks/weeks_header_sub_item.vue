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
        return 'label-dark label-bold';
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
  <div class="item-sublabel week-item-sublabel gl-pb-3" data-testid="week-item-sublabel">
    <span
      v-for="(subItem, index) in headerSubItems"
      :key="index"
      ref="weeklyDayCell"
      :class="getSubItemValueClass(subItem)"
      class="sublabel-value"
      data-testid="sublabel-value"
      >{{ getSubItemValue(subItem) }}</span
    >
    <span
      v-if="hasToday"
      :style="getIndicatorStyles($options.PRESET_TYPES.WEEKS, timeframeItem)"
      class="current-day-indicator-header preset-weeks"
    ></span>
  </div>
</template>
