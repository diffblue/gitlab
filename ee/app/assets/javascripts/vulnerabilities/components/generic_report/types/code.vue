<!-- eslint-disable vue/multi-word-component-names -->
<script>
import CodeBlock from '~/vue_shared/components/code_block.vue';

export default {
  components: {
    CodeBlock,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <code-block :code="value" />
</template>
