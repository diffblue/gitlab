<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { VSA_METRICS_GROUPS } from '~/analytics/shared/constants';
import { generateValueStreamsDashboardLink } from '~/analytics/shared/utils';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import PathNavigation from '~/analytics/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/analytics/cycle_analytics/components/stage_table.vue';
import ValueStreamFilters from '~/analytics/cycle_analytics/components/value_stream_filters.vue';
import { OVERVIEW_STAGE_ID } from '~/analytics/cycle_analytics/constants';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { METRICS_REQUESTS } from '../constants';
import DurationChart from './duration_chart.vue';
import TypeOfWorkCharts from './type_of_work_charts.vue';
import ValueStreamAggregationStatus from './value_stream_aggregation_status.vue';
import ValueStreamAggregatingWarning from './value_stream_aggregating_warning.vue';
import ValueStreamEmptyState from './value_stream_empty_state.vue';
import ValueStreamSelect from './value_stream_select.vue';
import DurationOverviewChart from './duration_overview_chart.vue';

export default {
  name: 'CycleAnalytics',
  components: {
    DurationChart,
    GlEmptyState,
    TypeOfWorkCharts,
    StageTable,
    PathNavigation,
    ValueStreamAggregationStatus,
    ValueStreamAggregatingWarning,
    ValueStreamEmptyState,
    ValueStreamFilters,
    ValueStreamMetrics,
    ValueStreamSelect,
    UrlSync,
    DurationOverviewChart,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    noDataSvgPath: {
      type: String,
      required: true,
    },
    noAccessSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'isLoading',
      'isLoadingStage',
      'selectedProjects',
      'selectedStage',
      'stages',
      'selectedStageEvents',
      'createdAfter',
      'createdBefore',
      'isLoadingValueStreams',
      'selectedStageError',
      'selectedValueStream',
      'pagination',
      'aggregation',
      'isCreatingAggregation',
      'groupPath',
      'features',
      'enableTasksByTypeChart',
      'enableProjectsFilter',
      'enableCustomizableStages',
    ]),
    ...mapGetters([
      'hasNoAccessError',
      'namespacePath',
      'activeStages',
      'selectedProjectIds',
      'selectedProjectFullPaths',
      'cycleAnalyticsRequestParams',
      'pathNavigationData',
      'isOverviewStageSelected',
      'selectedStageCount',
      'hasValueStreams',
    ]),
    isWaitingForNextAggregation() {
      return Boolean(this.selectedValueStream && !this.aggregation.lastRunAt);
    },
    shouldRenderEmptyState() {
      return this.isLoadingValueStreams || (!this.isCreatingAggregation && !this.hasValueStreams);
    },
    shouldRenderAggregationWarning() {
      return this.isCreatingAggregation || this.isWaitingForNextAggregation;
    },
    shouldRenderTasksByType() {
      return this.enableTasksByTypeChart && this.isOverviewStageSelected;
    },
    selectedStageReady() {
      return !this.hasNoAccessError && this.selectedStage;
    },
    shouldDisplayCreateMultipleValueStreams() {
      return Boolean(
        this.enableCustomizableStages &&
          !this.shouldRenderEmptyState &&
          !this.isLoadingValueStreams &&
          !this.isCreatingAggregation,
      );
    },
    hasDateRangeSet() {
      return this.createdAfter && this.createdBefore;
    },
    isAggregationStatusAvailable() {
      return this.aggregation.lastRunAt;
    },
    selectedValueStreamName() {
      return this.selectedValueStream?.name;
    },
    query() {
      const { project_ids, created_after, created_before } = this.cycleAnalyticsRequestParams;
      const paginationUrlParams = !this.isOverviewStageSelected
        ? {
            sort: this.pagination?.sort || null,
            direction: this.pagination?.direction || null,
            page: this.pagination?.page || null,
          }
        : {
            sort: null,
            direction: null,
            page: null,
          };

      return {
        value_stream_id: this.selectedValueStream?.id || null,
        project_ids,
        created_after,
        created_before,
        stage_id: (!this.isOverviewStageSelected && this.selectedStage?.id) || null, // the `overview` stage is always the default, so dont persist the id if its selected
        ...paginationUrlParams,
      };
    },
    stageCount() {
      return this.activeStages.length;
    },
    showDashboardsLink() {
      return Boolean(this.features?.groupLevelAnalyticsDashboard);
    },
    dashboardsPath() {
      if (this.showDashboardsLink) {
        const namespacePath = this.enableProjectsFilter ? this.namespacePath : this.groupPath;
        const projectsQuery = this.enableProjectsFilter
          ? this.selectedProjectFullPaths
          : [this.namespacePath];

        return generateValueStreamsDashboardLink(namespacePath, projectsQuery);
      }
      return null;
    },
  },
  methods: {
    ...mapActions([
      'fetchCycleAnalyticsData',
      'fetchStageData',
      'setSelectedProjects',
      'setSelectedStage',
      'setDefaultSelectedStage',
      'setDateRange',
      'updateStageTablePagination',
    ]),
    onProjectsSelect(projects) {
      this.setSelectedProjects(projects);
    },
    onStageSelect(stage) {
      if (stage.id === OVERVIEW_STAGE_ID) {
        this.setDefaultSelectedStage();
      } else {
        this.setSelectedStage(stage);
        this.updateStageTablePagination({ ...this.pagination, page: 1 });
      }
    },
    onSetDateRange({ startDate, endDate }) {
      this.setDateRange({
        createdAfter: new Date(startDate),
        createdBefore: new Date(endDate),
      });
    },
    onHandleUpdatePagination(data) {
      this.updateStageTablePagination(data);
    },
    onHandleReloadPage() {
      refreshCurrentPage();
    },
  },
  METRICS_REQUESTS,
  VSA_METRICS_GROUPS,
  aggregationPopoverOptions: {
    triggers: 'hover',
    placement: 'left',
  },
};
</script>
<template>
  <div>
    <value-stream-empty-state
      v-if="shouldRenderEmptyState"
      :is-loading="isLoadingValueStreams"
      :empty-state-svg-path="emptyStateSvgPath"
      :has-date-range-error="!hasDateRangeSet"
    />
    <template v-else>
      <div class="gl-mb-6">
        <h3>{{ __('Value Stream Analytics') }}</h3>
      </div>
      <div
        class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-sm-align-items-center gl-justify-content-space-between gl-mb-6 gl-gap-3"
      >
        <value-stream-select v-if="shouldDisplayCreateMultipleValueStreams" />
        <value-stream-aggregation-status v-if="isAggregationStatusAvailable" :data="aggregation" />
      </div>
      <value-stream-filters
        v-if="!shouldRenderAggregationWarning"
        class="gl-mb-6"
        :namespace-path="namespacePath"
        :group-path="groupPath"
        :selected-projects="selectedProjects"
        :start-date="createdAfter"
        :end-date="createdBefore"
        :has-project-filter="enableProjectsFilter"
        @selectProject="onProjectsSelect"
        @setDateRange="onSetDateRange"
      />
      <path-navigation
        v-if="selectedStageReady"
        data-testid="vsa-path-navigation"
        class="gl-w-full gl-mt-4"
        :loading="isLoading"
        :stages="pathNavigationData"
        :selected-stage="selectedStage"
        @selected="onStageSelect"
      />
      <value-stream-aggregating-warning
        v-if="shouldRenderAggregationWarning"
        class="gl-my-6"
        :value-stream-title="selectedValueStreamName"
        @reload="onHandleReloadPage"
      />
      <gl-empty-state
        v-else-if="hasNoAccessError"
        class="js-empty-state gl-mt-2"
        :title="__('You don’t have access to Value Stream Analytics for this group')"
        :svg-path="noAccessSvgPath"
        :description="
          __(
            'Only \'Reporter\' roles and above on tiers Premium and above can see Value Stream Analytics.',
          )
        "
      />
      <template v-else>
        <value-stream-metrics
          v-if="isOverviewStageSelected"
          :request-path="namespacePath"
          :request-params="cycleAnalyticsRequestParams"
          :requests="$options.METRICS_REQUESTS"
          :group-by="$options.VSA_METRICS_GROUPS"
          :dashboards-path="dashboardsPath"
        />
        <div :class="[isOverviewStageSelected ? 'gl-mt-2' : 'gl-mt-6']">
          <duration-overview-chart v-if="isOverviewStageSelected" class="gl-mb-6" />
          <duration-chart
            v-else
            class="gl-mb-6"
            :stages="activeStages"
            :selected-stage="selectedStage"
          />
          <type-of-work-charts v-if="shouldRenderTasksByType" class="gl-mb-6" />
        </div>
        <stage-table
          v-if="!isOverviewStageSelected"
          :is-loading="isLoading || isLoadingStage"
          :stage-events="selectedStageEvents"
          :selected-stage="selectedStage"
          :stage-count="selectedStageCount"
          :empty-state-message="selectedStageError"
          :no-data-svg-path="noDataSvgPath"
          :pagination="pagination"
          include-project-name
          @handleUpdatePagination="onHandleUpdatePagination"
        />
        <url-sync v-if="selectedStageReady" :query="query" />
      </template>
    </template>
  </div>
</template>
