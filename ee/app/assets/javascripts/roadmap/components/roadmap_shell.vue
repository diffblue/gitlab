<script>
import { mapActions, mapState } from 'vuex';

import eventHub from '../event_hub';
import { MILESTONES_GROUP, MILESTONES_SUBGROUP, MILESTONES_PROJECT } from '../constants';

import EpicsListSection from './epics_list_section.vue';
import MilestonesListSection from './milestones_list_section.vue';
import RoadmapTimelineSection from './roadmap_timeline_section.vue';

export default {
  components: {
    EpicsListSection,
    MilestonesListSection,
    RoadmapTimelineSection,
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    epics: {
      type: Array,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    currentGroupId: {
      type: Number,
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      containerStyles: {},
    };
  },
  computed: {
    ...mapState(['defaultInnerHeight', 'isShowingMilestones', 'milestonesType', 'milestones']),
    displayMilestones() {
      return Boolean(this.milestones.length) && this.isShowingMilestones;
    },
    milestonesToShow() {
      switch (this.milestonesType) {
        case MILESTONES_GROUP:
          return this.milestones.filter((m) => m.groupMilestone && !m.subgroupMilestone);
        case MILESTONES_SUBGROUP:
          return this.milestones.filter((m) => m.subgroupMilestone);
        case MILESTONES_PROJECT:
          return this.milestones.filter((m) => m.projectMilestone);
        default:
          return this.milestones;
      }
    },
  },
  mounted() {
    if (this.isShowingMilestones) {
      this.fetchMilestones();
    }
    this.$nextTick(() => {
      this.containerStyles = this.getContainerStyles();
    });
  },
  methods: {
    ...mapActions(['fetchMilestones']),
    handleScroll() {
      const { scrollTop, scrollLeft, clientHeight, scrollHeight } = this.$el;

      eventHub.$emit('epicsListScrolled', { scrollTop, scrollLeft, clientHeight, scrollHeight });
    },
    getContainerStyles() {
      const { top } = this.$el.getBoundingClientRect();
      return {
        height: `calc(100vh - ${top}px)`,
      };
    },
  },
};
</script>

<template>
  <div
    class="js-roadmap-shell gl-relative gl-w-full gl-overflow-x-auto"
    data-qa-selector="roadmap_shell"
    :style="containerStyles"
    @scroll="handleScroll"
  >
    <roadmap-timeline-section
      ref="roadmapTimeline"
      :preset-type="presetType"
      :epics="epics"
      :timeframe="timeframe"
    />
    <milestones-list-section
      v-if="displayMilestones"
      :preset-type="presetType"
      :milestones="milestonesToShow"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
    />
    <epics-list-section
      :preset-type="presetType"
      :epics="epics"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
      :has-filters-applied="hasFiltersApplied"
    />
  </div>
</template>
