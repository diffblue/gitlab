<script>
import { GlDrawer } from '@gitlab/ui';

export default {
  components: {
    GlDrawer,
  },
  props: {
    isOpen: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    getDrawerHeaderHeight() {
      const wrapperEl = document.querySelector('.roadmap-container');

      if (wrapperEl) {
        const topPosition = wrapperEl.getBoundingClientRect().top + window.pageYOffset;
        return `${topPosition}px`;
      }

      return '';
    },
  },
};
</script>

<template>
  <gl-drawer
    v-bind="$attrs"
    :open="isOpen"
    :header-height="getDrawerHeaderHeight()"
    @close="$emit('toggleSettings', $event)"
  >
    <template #title>
      <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">{{ __('Roadmap settings') }}</h2>
    </template>
  </gl-drawer>
</template>
