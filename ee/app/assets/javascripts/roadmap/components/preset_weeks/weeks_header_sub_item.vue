<script>
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
      presetType: PRESET_TYPES.WEEKS,
      indicatorStyle: {},
    };
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
  mounted() {
    this.$nextTick(() => {
      this.indicatorStyle = this.getIndicatorStyles();
    });
  },
  methods: {
    getSubItemValueClass(subItem) {
      // Show dark color text only for current & upcoming dates
      if (subItem.getTime() === this.currentDate.getTime()) {
        return 'label-dark label-bold';
      }
      if (subItem > this.currentDate) {
        return 'label-dark';
      }
      return '';
    },
  },
};
</script>

<template>
  <div class="item-sublabel">
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
      class="current-day-indicator-header preset-weeks position-absolute"
    ></span>
  </div>
</template>
