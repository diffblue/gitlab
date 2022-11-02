<script>
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  directives: {
    SafeHtml,
  },
  props: {
    html: {
      type: String,
      required: true,
    },
  },
  safeHtmlConfig: { ALLOWED_TAGS: [] },
};
</script>

<template>
  <span v-safe-html:[$options.safeHtmlConfig]="html"></span>
</template>
