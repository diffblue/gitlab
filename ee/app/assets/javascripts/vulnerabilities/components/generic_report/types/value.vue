<!-- eslint-disable vue/multi-word-component-names -->
<script>
export default {
  inheritAttrs: false,
  props: {
    value: {
      type: [String, Number, Boolean],
      required: true,
    },
  },
};
</script>
<template>
  <span>{{ value }}</span>
</template>
