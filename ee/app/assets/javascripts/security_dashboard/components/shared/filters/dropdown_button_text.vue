<script>
import { GlTruncate } from '@gitlab/ui';

export default {
  components: { GlTruncate },
  props: {
    items: {
      type: Array,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
  },
  computed: {
    firstItemText() {
      return this.items[0] || '';
    },
    additionalItemsCount() {
      // Prevent showing "+-1 more" when the array is empty.
      return Math.max(0, this.items.length - 1);
    },
    qaSelector() {
      return `filter_${this.name.toLowerCase().replaceAll(' ', '_')}_dropdown`;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <gl-truncate class="gl-min-w-0" :text="firstItemText" :data-qa-selector="qaSelector" />
    <span v-if="additionalItemsCount" class="gl-ml-2">
      {{ n__('+%d more', '+%d more', additionalItemsCount) }}
    </span>
  </div>
</template>
