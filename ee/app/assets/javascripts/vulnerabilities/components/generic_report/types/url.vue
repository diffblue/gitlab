<script>
import { GlFriendlyWrap, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
    GlFriendlyWrap,
  },
  inheritAttrs: false,
  props: {
    href: {
      type: String,
      required: true,
    },
  },
  wrapSymbols: ['/', '?', '&', '='],
};
</script>
<template>
  <gl-link :href="href">
    <gl-friendly-wrap :text="href" :symbols="$options.wrapSymbols" />
  </gl-link>
</template>
