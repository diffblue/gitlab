<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

import EpicsListEmpty from './epics_list_empty.vue';
import RoadmapFilters from './roadmap_filters.vue';
import RoadmapSettings from './roadmap_settings.vue';
import RoadmapShell from './roadmap_shell.vue';

export default {
  components: {
    EpicsListEmpty,
    GlLoadingIcon,
    RoadmapFilters,
    RoadmapSettings,
    RoadmapShell,
  },
  props: {
    emptyStateIllustrationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isSettingsSidebarOpen: false,
    };
  },
  computed: {
    ...mapState([
      'currentGroupId',
      'epicIid',
      'epics',
      'timeframe',
      'epicsFetchInProgress',
      'epicsFetchResultEmpty',
      'epicsFetchFailure',
      'isChildEpics',
      'hasFiltersApplied',
      'filterParams',
      'presetType',
      'timeframeRangeType',
    ]),
    showFilteredSearchbar() {
      if (this.epicsFetchResultEmpty) {
        return this.hasFiltersApplied;
      }
      return true;
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
  created() {
    this.fetchEpics();
  },
  methods: {
    ...mapActions(['fetchEpics']),
    toggleSettings() {
      this.isSettingsSidebarOpen = !this.isSettingsSidebarOpen;
    },
  },
};
</script>

<template>
  <div class="roadmap-app-container gl-h-full">
    <roadmap-filters v-if="showFilteredSearchbar && !epicIid" @toggleSettings="toggleSettings" />
    <div :class="{ 'overflow-reset': epicsFetchResultEmpty }" class="roadmap-container gl-relative">
      <gl-loading-icon v-if="epicsFetchInProgress" class="gl-my-5" size="lg" />
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
        :timeframe="timeframe"
        :current-group-id="currentGroupId"
        :has-filters-applied="hasFiltersApplied"
        :is-settings-sidebar-open="isSettingsSidebarOpen"
      />
      <roadmap-settings
        :is-open="isSettingsSidebarOpen"
        :timeframe-range-type="timeframeRangeType"
        data-testid="roadmap-settings"
        @toggleSettings="toggleSettings"
      />
    </div>
  </div>
</template>
