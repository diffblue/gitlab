<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  props: {
    enabled: {
      type: Boolean,
      required: true,
    },
    completed: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: true,
    },
  },
  computed: {
    icon() {
      return this.enabled ? 'chevron-down' : 'chevron-right';
    },
  },
  i18n: {
    label: __('Completed'),
  },
};
</script>
<template>
  <div class="gl-border-gray-100 gl-border-l-solid gl-border-1 gl-w-full gl-my-3 gl-pl-3">
    <div class="gl-display-flex gl-align-items-center">
      <span
        class="gl-display-flex gl-align-items-center gl-flex-grow-1 gl-font-weight-bold gl-text-blue-500"
        :class="{ 'gl-text-gray-400!': !enabled }"
      >
        <gl-icon :name="icon" :size="24" class="gl-text-gray-500 gl-mr-3" />
        {{ title }}
      </span>
      <gl-icon
        v-if="completed"
        name="check-circle-filled"
        :size="16"
        class="gl-text-green-600"
        :aria-label="$options.i18n.label"
      />
    </div>
  </div>
</template>
