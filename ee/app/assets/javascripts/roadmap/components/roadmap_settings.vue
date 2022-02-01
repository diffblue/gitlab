<script>
import { GlDrawer } from '@gitlab/ui';
import RoadmapDaterange from './roadmap_daterange.vue';
import RoadmapEpicsState from './roadmap_epics_state.vue';
import RoadmapProgressTracking from './roadmap_progress_tracking.vue';

export default {
  components: {
    GlDrawer,
    RoadmapDaterange,
    RoadmapEpicsState,
    RoadmapProgressTracking,
  },
  props: {
    isOpen: {
      type: Boolean,
      required: true,
    },
    timeframeRangeType: {
      type: String,
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
    <template #default>
      <roadmap-daterange :timeframe-range-type="timeframeRangeType" />
      <roadmap-epics-state />
      <roadmap-progress-tracking />
    </template>
  </gl-drawer>
</template>
