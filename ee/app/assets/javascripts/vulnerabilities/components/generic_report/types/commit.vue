<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  inject: ['commitPathTemplate'],
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    commitPath() {
      // Search for all occurences of "$COMMIT_SHA" within the given template, eg.: "/base/project/path/-/commit/$COMMIT_SHA"
      // NOTE: This should be swapped to using `String.prototype.replaceAll` and a raw string, once browser supported is wider (https://caniuse.com/?search=replaceAll)
      const allCommitShaPlaceHolders = /\$COMMIT_SHA/g;
      return this.commitPathTemplate.replace(allCommitShaPlaceHolders, this.value);
    },
  },
};
</script>

<template>
  <gl-link :href="commitPath">{{ value }}</gl-link>
</template>
