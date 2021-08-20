<script>
import CommonMixin from '../mixins/common_mixin';

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
  },
  data() {
    const currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0);

    return {
      currentDate,
      indicatorStyles: {},
    };
  },
  mounted() {
    this.$nextTick(() => {
      this.indicatorStyles = this.getIndicatorStyles();
    });
  },
};
</script>

<template>
  <span
    v-if="hasToday"
    :style="indicatorStyles"
    class="current-day-indicator js-current-day-indicator gl-absolute"
  ></span>
</template>
