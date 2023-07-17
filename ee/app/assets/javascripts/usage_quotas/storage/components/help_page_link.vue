<script>
import { GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'HelpPageLink',
  components: {
    GlLink,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    anchor: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    href() {
      return helpPagePath(this.path, { anchor: this.anchor });
    },
  },
};
</script>
<template>
  <gl-link :href="href">
    <slot></slot>
  </gl-link>
</template>
