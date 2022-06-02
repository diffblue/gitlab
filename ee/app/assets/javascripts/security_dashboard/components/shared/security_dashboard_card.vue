<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <section
    class="gl-border-solid gl-rounded-base gl-border-1 gl-border-gray-100 gl-display-flex gl-flex-direction-column"
  >
    <header class="gl-p-5">
      <h4 class="gl-mt-0 gl-mb-3" data-testid="title">
        <slot name="title"></slot>
      </h4>
      <p class="gl-text-secondary gl-m-0" data-testid="help-text">
        <slot name="help-text"></slot>
      </p>
      <div v-if="$scopedSlots.controls" class="gl-mt-5" data-testid="controls">
        <slot name="controls"></slot>
      </div>
    </header>

    <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-12" />
    <slot v-else></slot>
  </section>
</template>
