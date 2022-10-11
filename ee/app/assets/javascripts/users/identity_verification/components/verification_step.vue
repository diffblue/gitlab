<script>
import { GlCard, GlIcon } from '@gitlab/ui';

export default {
  name: 'VerificationStep',
  components: {
    GlCard,
    GlIcon,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    completed: {
      type: Boolean,
      required: true,
    },
    isActive: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    cardBodyClasses() {
      // Remove padding but add gl-pb-1 so body has the minimum height to retain
      // rounded bottom corners
      return { 'gl-p-0 gl-pb-1': !this.isActive };
    },
    titleClasses() {
      const borderClasses = 'gl-pb-5 gl-border-1 gl-border-b-solid gl-border-gray-100';
      const defaultClasses =
        'gl-font-base gl-my-2 gl-display-flex gl-justify-content-space-between';
      return { [borderClasses]: this.isActive, [defaultClasses]: true };
    },
  },
};
</script>
<template>
  <gl-card class="gl-mb-3" header-class="gl-bg-white gl-border-b-0" :body-class="cardBodyClasses">
    <template #header>
      <h3 :class="titleClasses">
        {{ title }}
        <gl-icon v-if="completed" name="check-circle-filled" class="gl-text-green-500" :size="16" />
      </h3>
    </template>
    <template #default>
      <slot v-if="isActive"></slot>
    </template>
  </gl-card>
</template>
