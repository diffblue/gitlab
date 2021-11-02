<script>
import { GlSegmentedControl } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'VulnerabilityChartButtons',
  components: {
    GlSegmentedControl,
  },
  props: {
    days: {
      type: Array,
      required: true,
    },
    activeDay: {
      type: Number,
      required: true,
    },
  },
  computed: {
    controlOptions() {
      return this.days.map((day) => ({ text: n__('1 Day', '%d Days', day), value: day }));
    },
  },
  methods: {
    inputHandler(days) {
      this.$emit('days-selected', days);
    },
  },
};
</script>

<template>
  <gl-segmented-control
    :options="controlOptions"
    :checked="activeDay"
    class="gl-display-flex"
    @input="inputHandler"
  />
</template>
