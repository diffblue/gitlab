<script>
import { GlIcon, GlPopover } from '@gitlab/ui';

export default {
  name: 'StorageTypeWarning',
  components: {
    GlPopover,
    GlIcon,
  },
  props: {
    content: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      mounted: false,
    };
  },
  mounted() {
    this.mounted = true;
  },
};
</script>

<template>
  <span>
    <gl-icon ref="glIcon" name="warning" class="gl-ml-2 gl-text-gray-500" />
    <gl-popover
      v-if="mounted"
      :target="$refs.glIcon"
      triggers="hover focus"
      placement="top"
      :content="content"
    />
  </span>
</template>
