<script>
import { GlCard, GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'VerificationStep',
  components: {
    GlCard,
    GlBadge,
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
  i18n: {
    completed: __('Completed'),
  },
};
</script>
<template>
  <gl-card class="gl-mb-3" header-class="gl-bg-white gl-border-b-0" :body-class="cardBodyClasses">
    <template #header>
      <h3 :class="titleClasses">
        {{ title }}
        <gl-badge v-if="completed" variant="success" icon="check-circle-filled" icon-size="sm">
          {{ $options.i18n.completed }}
        </gl-badge>
      </h3>
    </template>
    <template #default>
      <slot v-if="isActive"></slot>
    </template>
  </gl-card>
</template>
