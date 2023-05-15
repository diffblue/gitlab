<script>
import { GlPopover, GlProgressBar, GlIcon } from '@gitlab/ui';
import { mapState } from 'vuex';
import { __, sprintf } from '~/locale';
import {
  EPIC_DETAILS_CELL_WIDTH,
  PERCENTAGE,
  PRESET_TYPES,
  SMALL_TIMELINE_BAR,
  TIMELINE_CELL_MIN_WIDTH,
  PROGRESS_COUNT,
} from '../constants';
import CommonMixin from '../mixins/common_mixin';

import MonthsPresetMixin from '../mixins/months_preset_mixin';
import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';
import { generateKey } from '../utils/epic_utils';

export default {
  cellWidth: TIMELINE_CELL_MIN_WIDTH,
  components: {
    GlIcon,
    GlPopover,
    GlProgressBar,
  },
  mixins: [CommonMixin, QuartersPresetMixin, MonthsPresetMixin, WeeksPresetMixin],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
    epic: {
      type: Object,
      required: true,
    },
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    clientWidth: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    ...mapState(['progressTracking', 'isProgressTrackingActive']),
    timelineBarInnerStyle() {
      return {
        maxWidth: `${this.clientWidth - EPIC_DETAILS_CELL_WIDTH}px`,
      };
    },
    timelineBarWidth() {
      if (this.presetType === PRESET_TYPES.QUARTERS) {
        return this.getTimelineBarWidthForQuarters(this.epic);
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        return this.getTimelineBarWidthForMonths();
      }

      return this.getTimelineBarWidthForWeeks();
    },
    isTimelineBarSmall() {
      return this.timelineBarWidth < SMALL_TIMELINE_BAR;
    },
    timelineBarTitle() {
      return this.isTimelineBarSmall ? '...' : this.epic.title;
    },
    progressTrackingIsCount() {
      return this.progressTracking === PROGRESS_COUNT;
    },
    epicDescendants() {
      return this.progressTrackingIsCount
        ? this.epic.descendantCounts
        : this.epic.descendantWeightSum;
    },
    epicTotal() {
      if (this.epicDescendants) {
        const { openedIssues, closedIssues } = this.epicDescendants;
        return openedIssues + closedIssues;
      }
      return undefined;
    },
    epicPercentage() {
      return this.epicTotal
        ? Math.round((this.epicDescendants.closedIssues / this.epicTotal) * PERCENTAGE)
        : 0;
    },
    epicPercentageText() {
      const str = this.progressTrackingIsCount
        ? __('%{percentage}%% issues closed')
        : __('%{percentage}%% weight completed');
      return sprintf(str, { percentage: this.epicPercentage });
    },

    popoverText() {
      if (this.epicDescendants) {
        const str = this.progressTrackingIsCount
          ? __('%{completed} of %{total} issues closed')
          : __('%{completed} of %{total} weight completed');
        return sprintf(str, {
          completed: this.epicDescendants.closedIssues,
          total: this.epicTotal,
        });
      }
      return this.progressTrackingIsCount
        ? __('- of - issues closed')
        : __('- of - weight completed');
    },
    progressIcon() {
      return this.progressTrackingIsCount ? 'issue-closed' : 'weight';
    },
  },
  methods: {
    generateKey,
  },
};
</script>

<template>
  <div class="gl-relative gl-w-full">
    <a
      :id="generateKey(epic)"
      :href="epic.webUrl"
      :style="timelineBarStyles(epic)"
      :class="{ 'epic-bar-child-epic': epic.isChildEpic }"
      class="epic-bar rounded"
    >
      <div class="epic-bar-inner gl-px-3 gl-py-2" :style="timelineBarInnerStyle">
        <p class="epic-bar-title gl-text-truncate gl-m-0">{{ timelineBarTitle }}</p>

        <div
          v-if="!isTimelineBarSmall && isProgressTrackingActive"
          class="gl-display-flex gl-align-items-center"
        >
          <gl-progress-bar
            class="epic-bar-progress gl-flex-grow-1 gl-mr-2"
            :value="epicPercentage"
            aria-hidden="true"
          />
          <div class="gl-font-sm gl-display-flex gl-align-items-center gl-white-space-nowrap">
            <gl-icon class="gl-mr-1" :size="12" :name="progressIcon" />
            <p class="gl-m-0" :aria-label="epicPercentageText">{{ epicPercentage }}%</p>
          </div>
        </div>
      </div>
    </a>
    <gl-popover :target="generateKey(epic)" :title="epic.title" placement="left">
      <p class="gl-text-gray-500 gl-m-0">{{ timeframeString(epic) }}</p>
      <p class="gl-m-0">{{ popoverText }}</p>
    </gl-popover>
  </div>
</template>
