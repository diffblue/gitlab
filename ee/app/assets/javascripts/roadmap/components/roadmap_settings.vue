<script>
import { GlDrawer } from '@gitlab/ui';
import RoadmapDaterange from './roadmap_daterange.vue';
import RoadmapEpicsState from './roadmap_epics_state.vue';
import RoadmapMilestones from './roadmap_milestones.vue';
import RoadmapProgressTracking from './roadmap_progress_tracking.vue';
import RoadmapToggleLabels from './roadmap_toggle_labels.vue';

export default {
  components: {
    GlDrawer,
    RoadmapDaterange,
    RoadmapMilestones,
    RoadmapEpicsState,
    RoadmapProgressTracking,
    RoadmapToggleLabels,
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
};
</script>

<template>
  <gl-drawer
    v-bind="$attrs"
    :open="isOpen"
    class="gl-absolute"
    @close="$emit('toggleSettings', $event)"
  >
    <template #title>
      <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">{{ __('Roadmap settings') }}</h2>
    </template>
    <template #default>
      <roadmap-daterange :timeframe-range-type="timeframeRangeType" />
      <roadmap-milestones />
      <roadmap-epics-state />
      <roadmap-progress-tracking />
      <roadmap-toggle-labels />
    </template>
  </gl-drawer>
</template>
