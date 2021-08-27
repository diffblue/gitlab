<script>
import { GlAlert } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__, sprintf, __ } from '~/locale';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { formattedDate } from '../../shared/utils';
import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../constants';
import { uniqById } from '../utils';
import TasksByTypeChart from './tasks_by_type/tasks_by_type_chart.vue';
import TasksByTypeFilters from './tasks_by_type/tasks_by_type_filters.vue';

export default {
  name: 'TypeOfWorkCharts',
  components: { ChartSkeletonLoader, GlAlert, TasksByTypeChart, TasksByTypeFilters },
  computed: {
    ...mapState('typeOfWork', [
      'isLoadingTasksByTypeChart',
      'isLoadingTasksByTypeChartTopLabels',
      'errorMessage',
      'topRankedLabels',
    ]),
    ...mapGetters('typeOfWork', ['selectedTasksByTypeFilters', 'tasksByTypeChartData']),
    hasData() {
      return Boolean(this.tasksByTypeChartData?.data.length);
    },
    isLoading() {
      return Boolean(this.isLoadingTasksByTypeChart || this.isLoadingTasksByTypeChartTopLabels);
    },
    summaryDescription() {
      const {
        startDate,
        endDate,
        selectedProjectIds,
        currentGroup: { name: groupName },
      } = this.selectedTasksByTypeFilters;

      const selectedProjectCount = selectedProjectIds.length;
      const str =
        selectedProjectCount > 0
          ? s__(
              "CycleAnalytics|Showing data for group '%{groupName}' and %{selectedProjectCount} projects from %{startDate} to %{endDate}",
            )
          : s__(
              "CycleAnalytics|Showing data for group '%{groupName}' from %{startDate} to %{endDate}",
            );
      return sprintf(str, {
        startDate: formattedDate(startDate),
        endDate: formattedDate(endDate),
        groupName,
        selectedProjectCount,
      });
    },
    selectedSubjectFilter() {
      const {
        selectedTasksByTypeFilters: { subject },
      } = this;
      return subject || TASKS_BY_TYPE_SUBJECT_ISSUE;
    },
    selectedLabelIdsFilter() {
      return this.selectedTasksByTypeFilters?.selectedLabelIds || [];
    },
    error() {
      return this.errorMessage
        ? this.errorMessage
        : __('There is no data available. Please change your selection.');
    },
    initialGroupLabels() {
      return uniqById(this.topRankedLabels);
    },
  },
  methods: {
    ...mapActions('typeOfWork', ['setTasksByTypeFilters']),
    onUpdateFilter(e) {
      this.setTasksByTypeFilters(e);
    },
  },
};
</script>
<template>
  <div class="js-tasks-by-type-chart row">
    <chart-skeleton-loader v-if="isLoading" class="gl-my-4 gl-py-4" />
    <div v-else class="col-12">
      <h3>{{ s__('CycleAnalytics|Type of work') }}</h3>
      <p>{{ summaryDescription }}</p>
      <tasks-by-type-filters
        :default-group-labels="initialGroupLabels"
        :has-data="hasData"
        :selected-label-ids="selectedLabelIdsFilter"
        :subject-filter="selectedSubjectFilter"
        @update-filter="onUpdateFilter"
      />
      <tasks-by-type-chart
        v-if="hasData"
        :data="tasksByTypeChartData.data"
        :group-by="tasksByTypeChartData.groupBy"
      />
      <gl-alert v-else variant="info" :dismissible="false" class="gl-mt-3">
        {{ error }}
      </gl-alert>
    </div>
  </div>
</template>
