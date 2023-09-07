<script>
import { getSundays } from '~/lib/utils/datetime_utility';

import { PRESET_TYPES } from '../../constants';
import CommonMixin from '../../mixins/common_mixin';

export default {
  mixins: [CommonMixin],
  props: {
    currentDate: {
      type: Date,
      required: true,
    },
    timeframeItem: {
      type: Date,
      required: true,
    },
  },
  data() {
    return {
      presetType: PRESET_TYPES.MONTHS,
      indicatorStyle: {},
    };
  },
  computed: {
    headerSubItems() {
      return getSundays(this.timeframeItem);
    },
    headerSubItemClass() {
      const currentYear = this.currentDate.getFullYear();
      const currentMonth = this.currentDate.getMonth();
      const timeframeYear = this.timeframeItem.getFullYear();
      const timeframeMonth = this.timeframeItem.getMonth();

      // Show dark color text only for dates from current month and future months.
      return timeframeYear >= currentYear && timeframeMonth >= currentMonth ? 'label-dark' : '';
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.indicatorStyle = this.getIndicatorStyles();
    });
  },
  methods: {
    getSubItemValueClass(subItem) {
      const daysToClosestWeek = this.currentDate.getDate() - subItem.getDate();
      // Show dark color text only for upcoming dates
      // and current week date
      if (
        daysToClosestWeek <= 6 &&
        this.currentDate.getDate() >= subItem.getDate() &&
        this.currentDate.getFullYear() === subItem.getFullYear() &&
        this.currentDate.getMonth() === subItem.getMonth()
      ) {
        return 'label-dark label-bold';
      }
      if (subItem >= this.currentDate) {
        return 'label-dark';
      }
      return '';
    },
  },
};
</script>

<template>
  <div :class="headerSubItemClass" class="item-sublabel">
    <span
      v-for="(subItem, index) in headerSubItems"
      :key="index"
      :class="getSubItemValueClass(subItem)"
      class="sublabel-value"
      >{{ subItem.getDate() }}</span
    >
    <span
      v-if="hasToday"
      :style="indicatorStyle"
      class="current-day-indicator-header preset-months position-absolute"
    ></span>
  </div>
</template>
