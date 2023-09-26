<script>
import { GlFilteredSearchToken } from '@gitlab/ui';

export default {
  components: {
    GlFilteredSearchToken,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-filtered-search-token :config="config" v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <!-- This allows free-text search input for a project name or description, but does not suggest specific project matches -->
    <template #suggestions></template>
  </gl-filtered-search-token>
</template>
