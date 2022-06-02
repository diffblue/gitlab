<script>
export default {
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="gl-relative">
    <slot name="title"></slot>

    <slot v-if="disabled" name="disabled"></slot>
    <slot v-else></slot>

    <div
      v-if="disabled"
      class="gl-absolute gl-top-0 gl-bottom-0 gl-left-0 gl-right-0 gl-bg-white gl-opacity-5"
      data-testid="overlay"
    ></div>
  </div>
</template>
