<script>
import { debounce, cloneDeep, isEqual } from 'lodash';
import {
  stateFilter,
  severityFilter,
  vendorScannerFilter,
  simpleScannerFilter,
  activityFilter,
  getProjectFilter,
} from 'ee/security_dashboard/helpers';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ActivityFilter from './activity_filter.vue';
import ProjectFilter from './project_filter.vue';
import ScannerFilter from './scanner_filter.vue';
import SimpleFilter from './simple_filter.vue';

export default {
  components: { SimpleFilter, ScannerFilter, ActivityFilter, ProjectFilter },
  mixins: [glFeatureFlagsMixin()],
  inject: ['dashboardType'],
  props: {
    projects: { type: Array, required: false, default: undefined },
  },
  data() {
    return {
      filterQuery: {},
    };
  },
  computed: {
    isProjectDashboard() {
      return this.dashboardType === DASHBOARD_TYPES.PROJECT;
    },
    isPipeline() {
      return this.dashboardType === DASHBOARD_TYPES.PIPELINE;
    },
    isGroupDashboard() {
      return this.dashboardType === DASHBOARD_TYPES.GROUP;
    },
    isInstanceDashboard() {
      return this.dashboardType === DASHBOARD_TYPES.INSTANCE;
    },
    shouldShowProjectFilter() {
      return this.isGroupDashboard || this.isInstanceDashboard;
    },
    shouldShowNewProjectFilter() {
      return this.glFeatures.vulnReportNewProjectFilter && this.shouldShowProjectFilter;
    },
    projectFilter() {
      return getProjectFilter(this.projects);
    },
  },
  methods: {
    updateFilterQuery(query) {
      const oldQuery = cloneDeep(this.filterQuery);
      this.filterQuery = { ...this.filterQuery, ...query };

      if (!isEqual(oldQuery, this.filterQuery)) {
        this.emitFilterChange();
      }
    },
    // When this component is first shown, every filter will emit its own @filter-changed event at
    // the same time, which will trigger this method multiple times. We'll debounce it so that it
    // only runs once.
    emitFilterChange: debounce(function emit() {
      this.$emit('filterChange', this.filterQuery);
    }),
  },
  simpleFilters: [stateFilter, severityFilter],
  vendorScannerFilter,
  simpleScannerFilter,
  activityFilter,
};
</script>

<template>
  <div
    class="vulnerability-report-filters gl-p-5 gl-bg-gray-10 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
  >
    <simple-filter
      v-for="filter in $options.simpleFilters"
      :key="filter.id"
      :filter="filter"
      :data-testid="filter.id"
      @filter-changed="updateFilterQuery"
    />

    <scanner-filter
      v-if="isProjectDashboard"
      :filter="$options.vendorScannerFilter"
      @filter-changed="updateFilterQuery"
    />
    <simple-filter
      v-else
      :filter="$options.simpleScannerFilter"
      :data-testid="$options.simpleScannerFilter.id"
      @filter-changed="updateFilterQuery"
    />

    <activity-filter
      v-if="!isPipeline"
      :filter="$options.activityFilter"
      @filter-changed="updateFilterQuery"
    />

    <project-filter
      v-if="shouldShowNewProjectFilter"
      :filter="projectFilter"
      @filter-changed="updateFilterQuery"
    />
    <simple-filter
      v-else-if="shouldShowProjectFilter"
      :filter="projectFilter"
      :data-testid="projectFilter.id"
      @filter-changed="updateFilterQuery"
    />
  </div>
</template>
