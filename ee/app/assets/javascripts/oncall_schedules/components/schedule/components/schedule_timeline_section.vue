<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import { PRESET_TYPES, TIMELINE_CELL_WIDTH } from 'ee/oncall_schedules/constants';
import updateTimelineWidthMutation from 'ee/oncall_schedules/graphql/mutations/update_timeline_width.mutation.graphql';
import DaysHeaderItem from './preset_days/days_header_item.vue';
import WeeksHeaderItem from './preset_weeks/weeks_header_item.vue';

export default {
  PRESET_TYPES,
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  components: {
    DaysHeaderItem,
    WeeksHeaderItem,
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
  },
  computed: {
    presetIsDay() {
      return this.presetType === this.$options.PRESET_TYPES.DAYS;
    },
  },
  mounted() {
    this.updateShiftStyles();
  },
  methods: {
    updateShiftStyles() {
      const timelineWidth = this.$refs.timelineHeaderWrapper.getBoundingClientRect().width;
      // Don't re-size the schedule grid if we collapse another schedule
      if (timelineWidth === 0) {
        return;
      }

      this.$apollo.mutate({
        mutation: updateTimelineWidthMutation,
        variables: {
          timelineWidth: timelineWidth - TIMELINE_CELL_WIDTH,
        },
      });
    },
  },
};
</script>

<template>
  <div class="timeline-section clearfix gl-sticky gl-top-0">
    <div>
      <span class="timeline-header-label gl-text-gray-700 gl-float-left">{{
        presetIsDay ? __('Hour') : __('Date')
      }}</span>
    </div>
    <div
      ref="timelineHeaderWrapper"
      v-gl-resize-observer="updateShiftStyles"
      data-testid="timeline-header-wrapper"
    >
      <days-header-item v-if="presetIsDay" :timeframe-item="timeframe[0]" />
      <weeks-header-item
        v-for="(timeframeItem, index) in timeframe"
        v-else
        :key="index"
        :timeframe-index="index"
        :timeframe-item="timeframeItem"
        :timeframe="timeframe"
        :preset-type="presetType"
      />
    </div>
  </div>
</template>
