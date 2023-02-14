<script>
import { delay } from 'lodash';

import { EPIC_HIGHLIGHT_REMOVE_AFTER } from '../constants';
import CommonMixin from '../mixins/common_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';

import CurrentDayIndicator from './current_day_indicator.vue';

import EpicItemDetails from './epic_item_details.vue';
import EpicItemTimeline from './epic_item_timeline.vue';

export default {
  components: {
    CurrentDayIndicator,
    EpicItemDetails,
    EpicItemTimeline,
  },
  mixins: [CommonMixin, QuartersPresetMixin, MonthsPresetMixin, WeeksPresetMixin],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    epic: {
      type: Object,
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
    clientWidth: {
      type: Number,
      required: false,
      default: 0,
    },
    childLevel: {
      type: Number,
      required: true,
    },
    childrenEpics: {
      type: Object,
      required: true,
    },
    childrenFlags: {
      type: Object,
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    const currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0);

    return {
      currentDate,
    };
  },
  computed: {
    /**
     * In case Epic start date is out of range
     * we need to use original date instead of proxy date
     */
    startDate() {
      if (this.epic.startDateOutOfRange) {
        return this.epic.originalStartDate;
      }

      return this.epic.startDate;
    },
    /**
     * In case Epic end date is out of range
     * we need to use original date instead of proxy date
     */
    endDate() {
      if (this.epic.endDateOutOfRange) {
        return this.epic.originalEndDate;
      }
      return this.epic.endDate;
    },
    isChildrenEmpty() {
      return this.childrenEpics[this.epic.id] && this.childrenEpics[this.epic.id].length === 0;
    },
    hasChildrenToShow() {
      return this.childrenFlags[this.epic.id].itemExpanded && this.childrenEpics[this.epic.id];
    },
  },
  updated() {
    this.removeHighlight();
  },
  methods: {
    /**
     * When new epics are added to the list on
     * timeline scroll, we set `newEpic` flag
     * as true and then use it in template
     * to set `newly-added-epic` class for
     * highlighting epic using CSS animations
     *
     * Once animation is complete, we need to
     * remove the flag so that animation is not
     * replayed when list is re-rendered.
     */
    removeHighlight() {
      if (this.epic.newEpic) {
        this.$nextTick(() => {
          delay(() => {
            // eslint-disable-next-line vue/no-mutating-props
            this.epic.newEpic = false;
          }, EPIC_HIGHLIGHT_REMOVE_AFTER);
        });
      }
    },
  },
};
</script>

<template>
  <div class="epic-item-container">
    <div
      :class="{ 'newly-added-epic': epic.newEpic }"
      class="epics-list-item gl-clearfix gl-display-flex gl-flex-direction-row gl-align-items-stretch"
    >
      <epic-item-details
        :epic="epic"
        :current-group-id="currentGroupId"
        :timeframe-string="timeframeString(epic)"
        :child-level="childLevel"
        :children-flags="childrenFlags"
        :has-filters-applied="hasFiltersApplied"
        :is-children-empty="isChildrenEmpty"
      />
      <span
        v-for="(timeframeItem, index) in timeframe"
        :key="index"
        class="epic-timeline-cell gl-display-flex"
        data-qa-selector="epic_timeline_cell"
      >
        <!--
          CurrentDayIndicator internally checks if a given timeframeItem is for today.
          However, we are doing a duplicate check (index === todaysIndex) here -
          so that the the indicator is rendered once.
          This optimization is only done in this component(EpicItem). -->
        <current-day-indicator
          v-if="index === todaysIndex"
          :preset-type="presetType"
          :timeframe-item="timeframeItem"
        />
        <epic-item-timeline
          v-if="index === roadmapItemIndex"
          :preset-type="presetType"
          :timeframe="timeframe"
          :timeframe-item="timeframeItem"
          :epic="epic"
          :start-date="startDate"
          :end-date="endDate"
          :client-width="clientWidth"
        />
      </span>
    </div>
    <epic-item-container
      v-if="hasChildrenToShow"
      :preset-type="presetType"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
      :client-width="clientWidth"
      :children="
        childrenEpics[epic.id] ||
        [] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */
      "
      :child-level="childLevel + 1"
      :children-epics="childrenEpics"
      :children-flags="childrenFlags"
      :has-filters-applied="hasFiltersApplied"
    />
  </div>
</template>
