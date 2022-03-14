<script>
import { GlEmptyState } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/cycle_analytics/components/stage_table.vue';
import ValueStreamFilters from '~/cycle_analytics/components/value_stream_filters.vue';
import { OVERVIEW_STAGE_ID } from '~/cycle_analytics/constants';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { METRICS_REQUESTS } from '../constants';
import DurationChart from './duration_chart.vue';
import TypeOfWorkCharts from './type_of_work_charts.vue';
import ValueStreamAggregationStatus from './value_stream_aggregation_status.vue';
import ValueStreamSelect from './value_stream_select.vue';

export default {
  name: 'CycleAnalytics',
  components: {
    DurationChart,
    GlEmptyState,
    TypeOfWorkCharts,
    StageTable,
    PathNavigation,
    ValueStreamAggregationStatus,
    ValueStreamFilters,
    ValueStreamMetrics,
    ValueStreamSelect,
    UrlSync,
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
      'currentGroup',
      'selectedProjects',
      'selectedStage',
      'stages',
      'selectedStageEvents',
      'errorCode',
      'createdAfter',
      'createdBefore',
      'isLoadingValueStreams',
      'selectedStageError',
      'selectedValueStream',
      'pagination',
      'aggregation',
    ]),
    ...mapGetters([
      'hasNoAccessError',
      'currentGroupPath',
      'activeStages',
      'selectedProjectIds',
      'enableCustomOrdering',
      'cycleAnalyticsRequestParams',
      'pathNavigationData',
      'isOverviewStageSelected',
      'selectedStageCount',
    ]),
    shouldRenderEmptyState() {
      return !this.currentGroup && !this.isLoading;
    },
    shouldDisplayFilters() {
      return !this.errorCode && !this.hasNoAccessError;
    },
    selectedStageReady() {
      return !this.hasNoAccessError && this.selectedStage;
    },
    shouldDisplayCreateMultipleValueStreams() {
      return Boolean(!this.shouldRenderEmptyState && !this.isLoadingValueStreams);
    },
    hasDateRangeSet() {
      return this.createdAfter && this.createdBefore;
    },
    isAggregationEnabled() {
      return this.aggregation?.enabled;
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
  },
  METRICS_REQUESTS,
  aggregationPopoverOptions: {
    triggers: 'hover',
    placement: 'left',
  },
};
</script>
<template>
  <div>
    <div
      class="gl-mb-3 gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-justify-content-space-between"
    >
      <h3>{{ __('Value Stream Analytics') }}</h3>
      <div class="gl-display-flex gl-flex-direction-row gl-align-items-center gl-mt-0 gl-sm-mt-5">
        <value-stream-aggregation-status v-if="isAggregationEnabled" :data="aggregation" />
        <value-stream-select v-if="shouldDisplayCreateMultipleValueStreams" />
      </div>
    </div>
    <gl-empty-state
      v-if="shouldRenderEmptyState"
      :title="__('Value Stream Analytics can help you determine your team’s velocity')"
      :description="
        __('Filter parameters are not valid. Make sure that the end date is after the start date.')
      "
      :svg-path="emptyStateSvgPath"
    />
    <div v-else class="gl-max-w-full">
      <path-navigation
        v-if="selectedStageReady"
        data-testid="vsa-path-navigation"
        class="gl-w-full gl-pb-2"
        :loading="isLoading"
        :stages="pathNavigationData"
        :selected-stage="selectedStage"
        @selected="onStageSelect"
      />
      <value-stream-filters
        :group-id="currentGroup.id"
        :group-path="currentGroupPath"
        :selected-projects="selectedProjects"
        :start-date="createdAfter"
        :end-date="createdBefore"
        @selectProject="onProjectsSelect"
        @setDateRange="onSetDateRange"
      />
      <gl-empty-state
        v-if="hasNoAccessError"
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
        <div :class="[isOverviewStageSelected ? 'gl-mt-2' : 'gl-mt-6']">
          <value-stream-metrics
            v-if="isOverviewStageSelected"
            :request-path="currentGroupPath"
            :request-params="cycleAnalyticsRequestParams"
            :requests="$options.METRICS_REQUESTS"
          />
          <duration-chart class="gl-mt-3" :stages="activeStages" :selected-stage="selectedStage" />
          <type-of-work-charts v-if="isOverviewStageSelected" />
          <stage-table
            v-if="!isOverviewStageSelected"
            class="gl-mt-5"
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
        </div>
        <url-sync v-if="selectedStageReady" :query="query" />
      </template>
    </div>
  </div>
</template>
