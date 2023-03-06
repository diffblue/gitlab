<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';

export default {
  name: 'SingleStat',
  components: {
    GlSingleStat,
  },
  props: {
    data: {
      type: [String, Number],
      required: false,
      default: 0,
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    title() {
      return this.options.title ?? '';
    },
    decimalPlaces() {
      // Only set the decimals places if this has data
      return (this.data && parseInt(this.options.decimalPlaces, 10)) || 0;
    },
  },
};
</script>

<template>
  <div class="gl-h-full gl-display-flex gl-align-items-center">
    <gl-single-stat
      class="gl-p-0!"
      :value="data"
      :title="title"
      :meta-text="options.metaText"
      :meta-icon="options.metaIcon"
      :title-icon="options.titleIcon"
      :unit="options.unit"
      :animation-decimal-places="decimalPlaces"
      :should-animate="true"
      variant="muted"
    />
  </div>
</template>
