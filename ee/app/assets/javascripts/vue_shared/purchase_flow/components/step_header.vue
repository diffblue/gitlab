<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  props: {
    isFinished: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    isEditable: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['edit'],
  i18n: {
    edit: s__('Checkout|Edit'),
  },
};
</script>
<template>
  <div
    class="gl-display-flex gl-justify-content-space-between gl-align-items-center"
    :class="isFinished ? 'gl-mb-2' : ''"
  >
    <div class="gl-display-flex gl-align-items-center">
      <gl-icon
        v-show="isFinished"
        class="gl-mr-2 gl-text-green-500"
        :size="16"
        :aria-label="title"
        name="check-circle"
      />
      <h5 class="gl-my-0">{{ title }}</h5>
    </div>
    <div
      v-if="isEditable"
      class="gl-display-flex gl-flex-direction-column gl-justify-content-center"
    >
      <gl-button size="small" @click="$emit('edit')">{{ $options.i18n.edit }}</gl-button>
    </div>
  </div>
</template>
