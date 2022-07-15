<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlAlert, GlIcon, GlTooltip, GlSafeHtmlDirective } from '@gitlab/ui';
import { s__, sprintf, __, n__ } from '~/locale';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { formattedDate } from '../../shared/utils';
import { TASKS_BY_TYPE_SUBJECT_ISSUE, TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS } from '../constants';
import TasksByTypeChart from './tasks_by_type/tasks_by_type_chart.vue';
import TasksByTypeFilters from './tasks_by_type/tasks_by_type_filters.vue';

export default {
  name: 'TypeOfWorkCharts',
  components: {
    ChartSkeletonLoader,
    GlAlert,
    GlIcon,
    GlTooltip,
    TasksByTypeChart,
    TasksByTypeFilters,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  computed: {
    ...mapState('typeOfWork', [
      'isLoadingTasksByTypeChart',
      'isLoadingTasksByTypeChartTopLabels',
      'errorMessage',
    ]),
    ...mapGetters('typeOfWork', [
      'selectedTasksByTypeFilters',
      'tasksByTypeChartData',
      'selectedLabelIds',
    ]),
    hasData() {
      return Boolean(this.tasksByTypeChartData?.data.length);
    },
    isLoading() {
      return Boolean(this.isLoadingTasksByTypeChart || this.isLoadingTasksByTypeChartTopLabels);
    },
    selectedFiltersDescription() {
      const { selectedLabelIds, selectedSubjectFilterText } = this;
      return sprintf(
        n__(
          'ValueStreamAnalytics|%{subjectFilterText} and %{selectedLabelIds} label',
          'ValueStreamAnalytics|%{subjectFilterText} and %{selectedLabelIds} labels',
          selectedLabelIds.length,
        ),
        {
          subjectFilterText: selectedSubjectFilterText.toLowerCase(),
          selectedLabelIds: selectedLabelIds.length,
        },
      );
    },
    tooltipText() {
      const {
        createdAfter,
        createdBefore,
        selectedProjectIds,
        currentGroup: { name: groupName },
      } = this.selectedTasksByTypeFilters;

      const selectedProjectCount = selectedProjectIds.length;
      const str =
        selectedProjectCount > 0
          ? s__(
              "ValueStreamAnalytics|Shows %{selectedFiltersDescription} for group '%{groupName}' and %{selectedProjectCount} projects from %{createdAfter} to %{createdBefore}",
            )
          : s__(
              "ValueStreamAnalytics|Shows %{selectedFiltersDescription} for group '%{groupName}' from %{createdAfter} to %{createdBefore}",
            );
      return sprintf(str, {
        selectedFiltersDescription: this.selectedFiltersDescription,
        createdAfter: formattedDate(createdAfter),
        createdBefore: formattedDate(createdBefore),
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
    selectedSubjectFilterText() {
      const { selectedSubjectFilter } = this;
      return (
        TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS[selectedSubjectFilter] ||
        TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS[TASKS_BY_TYPE_SUBJECT_ISSUE]
      );
    },
    error() {
      return this.errorMessage
        ? this.errorMessage
        : __('There is no data available. Please change your selection.');
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
  <div class="js-tasks-by-type-chart">
    <chart-skeleton-loader v-if="isLoading" class="gl-my-4 gl-py-4" />
    <div v-else>
      <div class="gl-display-flex gl-justify-content-space-between">
        <h4 class="gl-mt-0">
          {{ s__('ValueStreamAnalytics|Tasks by type') }}&nbsp;
          <span ref="tooltipTrigger" data-testid="vsa-task-by-type-description">
            <gl-icon name="information-o" />
          </span>
          <gl-tooltip :target="() => $refs.tooltipTrigger" boundary="viewport" placement="top">
            <span v-safe-html="tooltipText"></span>
          </gl-tooltip>
        </h4>
        <tasks-by-type-filters
          :subject-filter="selectedSubjectFilter"
          @update-filter="onUpdateFilter"
        />
      </div>
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
