<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'VulnerabilityChartButtons',
  components: {
    GlButtonGroup,
    GlButton,
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
    buttons() {
      return this.days.map((day) => ({ text: n__('1 Day', '%d Days', day), day }));
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
  <gl-button-group class="gl-display-flex">
    <gl-button
      v-for="{ text, day } in buttons"
      :key="day"
      :selected="day === activeDay"
      @click="inputHandler(day)"
    >
      {{ text }}
    </gl-button>
  </gl-button-group>
</template>
