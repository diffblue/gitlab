<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    isFinished: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="d-flex">
    <gl-icon
      v-show="isFinished"
      class="checkmark gl-mr-3"
      :size="16"
      :aria-label="title"
      name="check-circle"
    />
    <h5 class="gl-mt-0 gl-mb-3">{{ title }}</h5>
  </div>
</template>
