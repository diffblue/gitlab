<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import {
  EXTEND_AS,
  EPICS_LIMIT_DISMISSED_COOKIE_NAME,
  EPICS_LIMIT_DISMISSED_COOKIE_TIMEOUT,
  DATE_RANGES,
} from '../constants';
import eventHub from '../event_hub';
import EpicsListEmpty from './epics_list_empty.vue';
import RoadmapFilters from './roadmap_filters.vue';
import RoadmapShell from './roadmap_shell.vue';

export default {
  i18n: {
    warningTitle: s__('GroupRoadmap|Some of your epics might not be visible'),
    warningBody: s__(
      'GroupRoadmap|Roadmaps can display up to 1,000 epics. These appear in your selected sort order.',
    ),
    warningButtonLabel: __('Learn more'),
  },
  components: {
    EpicsListEmpty,
    GlAlert,
    GlLoadingIcon,
    RoadmapFilters,
    RoadmapShell,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    timeframeRangeType: {
      type: String,
      required: false,
      default: DATE_RANGES.CURRENT_QUARTER,
    },
    presetType: {
      type: String,
      required: true,
    },
    emptyStateIllustrationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isWarningDismissed: Cookies.get(EPICS_LIMIT_DISMISSED_COOKIE_NAME) === 'true',
    };
  },
  computed: {
    ...mapState([
      'currentGroupId',
      'epics',
      'milestones',
      'timeframe',
      'extendedTimeframe',
      'epicsFetchInProgress',
      'epicsFetchForTimeframeInProgress',
      'epicsFetchResultEmpty',
      'epicsFetchFailure',
      'isChildEpics',
      'hasFiltersApplied',
      'milestonesFetchFailure',
      'filterParams',
    ]),
    showFilteredSearchbar() {
      if (this.glFeatures.asyncFiltering) {
        if (this.epicsFetchResultEmpty) {
          return this.hasFiltersApplied;
        }
        return true;
      }
      return false;
    },
    timeframeStart() {
      return this.timeframe[0];
    },
    timeframeEnd() {
      const last = this.timeframe.length - 1;
      return this.timeframe[last];
    },
    isWarningVisible() {
      return !this.isWarningDismissed && this.epics.length > gon?.roadmap_epics_limit;
    },
  },
  mounted() {
    this.fetchEpics();
    this.fetchMilestones();
  },
  methods: {
    ...mapActions([
      'fetchEpics',
      'fetchEpicsForTimeframe',
      'extendTimeframe',
      'refreshEpicDates',
      'fetchMilestones',
      'refreshMilestoneDates',
    ]),
    /**
     * Once timeline is expanded (either with prepend or append)
     * We need performing following actions;
     *
     * 1. Reset start and end edges of the timeline for
     *    infinite scrolling to continue further.
     * 2. Re-render timeline bars to account for
     *    updated timeframe.
     * 3. In case of prepending timeframe,
     *    reset scroll-position (due to DOM prepend).
     */
    processExtendedTimeline({ extendAs = EXTEND_AS.PREPEND, roadmapTimelineEl, itemsCount = 0 }) {
      // Re-render timeline bars with updated timeline
      eventHub.$emit('refreshTimeline', {
        todayBarReady: extendAs === EXTEND_AS.PREPEND,
      });

      if (extendAs === EXTEND_AS.PREPEND) {
        // When DOM is prepended with elements
        // we compensate the scrolling for added elements' width
        roadmapTimelineEl.parentElement.scrollBy(
          roadmapTimelineEl.querySelector('.timeline-header-item').clientWidth * itemsCount,
          0,
        );
      }
    },
    handleScrollToExtend({ el: roadmapTimelineEl, extendAs = EXTEND_AS.PREPEND }) {
      this.extendTimeframe({ extendAs });
      this.refreshEpicDates();
      this.refreshMilestoneDates();

      this.$nextTick(() => {
        this.fetchEpicsForTimeframe({
          timeframe: this.extendedTimeframe,
        })
          .then(() => {
            this.$nextTick(() => {
              // Re-render timeline bars with updated timeline
              this.processExtendedTimeline({
                itemsCount: this.extendedTimeframe ? this.extendedTimeframe.length : 0,
                extendAs,
                roadmapTimelineEl,
              });
            });
          })
          .catch(() => {});
      });
    },
    dismissTooManyEpicsWarning() {
      Cookies.set(EPICS_LIMIT_DISMISSED_COOKIE_NAME, 'true', {
        expires: EPICS_LIMIT_DISMISSED_COOKIE_TIMEOUT,
      });
      this.isWarningDismissed = true;
    },
  },
};
</script>

<template>
  <div class="roadmap-app-container gl-h-full">
    <roadmap-filters v-if="showFilteredSearchbar" :timeframe-range-type="timeframeRangeType" />
    <gl-alert
      v-if="isWarningVisible"
      variant="warning"
      :title="$options.i18n.warningTitle"
      :primary-button-text="$options.i18n.warningButtonLabel"
      primary-button-link="https://docs.gitlab.com/ee/user/group/roadmap/"
      data-testid="epics_limit_callout"
      @dismiss="dismissTooManyEpicsWarning"
      >{{ $options.i18n.warningBody }}</gl-alert
    >
    <div :class="{ 'overflow-reset': epicsFetchResultEmpty }" class="roadmap-container">
      <gl-loading-icon v-if="epicsFetchInProgress" class="gl-mt-5" size="md" />
      <epics-list-empty
        v-else-if="epicsFetchResultEmpty"
        :preset-type="presetType"
        :timeframe-start="timeframeStart"
        :timeframe-end="timeframeEnd"
        :has-filters-applied="hasFiltersApplied"
        :empty-state-illustration-path="emptyStateIllustrationPath"
        :is-child-epics="isChildEpics"
        :filter-params="filterParams"
      />
      <roadmap-shell
        v-else-if="!epicsFetchFailure"
        :preset-type="presetType"
        :epics="epics"
        :milestones="milestones"
        :timeframe="timeframe"
        :current-group-id="currentGroupId"
        :has-filters-applied="hasFiltersApplied"
        @onScrollToStart="handleScrollToExtend"
        @onScrollToEnd="handleScrollToExtend"
      />
    </div>
  </div>
</template>
