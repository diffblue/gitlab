<script>
import { GlButton, GlCollapse } from '@gitlab/ui';

export default {
  name: 'ProductAnalyticsOnboardingSetupCollapse',
  components: { GlButton, GlCollapse },
  props: {
    label: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isVisible: this.visible,
    };
  },
  methods: {
    toggleVisibility() {
      this.isVisible = !this.isVisible;
    },
  },
};
</script>

<template>
  <section class="gl-border-t gl-border-gray-100">
    <div
      class="gl-py-6 gl-display-flex gl-flex-wrap gl-justify-content-space-between gl-align-items-flex-start"
    >
      <div>
        <h4 class="gl-mt-0 gl-mb-2">{{ label }}</h4>
        <p class="gl-mb-0">{{ description }}</p>
      </div>
      <gl-button category="primary" @click="toggleVisibility">
        {{ isVisible ? __('Collapse') : __('Expand') }}
      </gl-button>
    </div>

    <gl-collapse :visible="isVisible">
      <div class="gl-mb-6">
        <slot></slot>
      </div>
    </gl-collapse>
  </section>
</template>
