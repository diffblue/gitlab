<script>
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  directives: { SafeHtml },
  props: {
    readmeHtml: {
      required: true,
      type: String,
    },
  },
};
</script>
<template>
  <div v-safe-html="readmeHtml"></div>
</template>
