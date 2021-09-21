<script>
import { GlAlert } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { mapState } from 'vuex';
import { filterToQueryObject } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { THROUGHPUT_CHART_STRINGS } from '../constants';
import throughputChartQueryBuilder from '../graphql/throughput_chart_query_builder';
import { formatThroughputChartData, computeMttmData } from '../utils';
import ThroughputStats from './throughput_stats.vue';

export default {
  name: 'ThroughputChart',
  components: {
    GlAreaChart,
    GlAlert,
    ChartSkeletonLoader,
    ThroughputStats,
  },
  inject: ['fullPath'],
  props: {
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
  },
  data() {
    return {
      throughputChartData: [],
      hasError: false,
    };
  },
  apollo: {
    throughputChartData: {
      query() {
        return throughputChartQueryBuilder(this.startDate, this.endDate);
      },
      variables() {
        const options = filterToQueryObject({
          sourceBranches: this.selectedSourceBranch,
          targetBranches: this.selectedTargetBranch,
          milestoneTitle: this.selectedMilestone,
          authorUsername: this.selectedAuthor,
          assigneeUsername: this.selectedAssignee,
          labels: this.selectedLabelList,
        });

        return {
          fullPath: this.fullPath,
          ...options,
          notLabels: options['not[labels]'],
          notMilestoneTitle: options['not[milestoneTitle]'],
        };
      },
      error() {
        this.hasError = true;
      },
      context: {
        isSingleRequest: true,
      },
    },
  },
  computed: {
    ...mapState('filters', {
      selectedSourceBranch: (state) => state.branches.source.selected,
      selectedTargetBranch: (state) => state.branches.target.selected,
      selectedMilestone: (state) => state.milestones.selected,
      selectedAuthor: (state) => state.authors.selected,
      selectedAssignee: (state) => state.assignees.selected,
      selectedLabelList: (state) => state.labels.selectedList,
    }),
    chartOptions() {
      return {
        xAxis: {
          name: THROUGHPUT_CHART_STRINGS.X_AXIS_TITLE,
          type: 'category',
          axisLabel: {
            formatter: (value) => {
              return value.split(' ')[0]; // Aug 2020 => Aug
            },
          },
        },
        yAxis: {
          name: THROUGHPUT_CHART_STRINGS.Y_AXIS_TITLE,
          axisLabel: {
            formatter: (value) => value,
          },
        },
      };
    },
    formattedThroughputChartData() {
      return formatThroughputChartData(this.throughputChartData);
    },
    isLoading() {
      return !this.hasError && this.$apollo.queries.throughputChartData.loading;
    },
    chartDataAvailable() {
      return this.formattedThroughputChartData[0]?.data?.some((entry) => Boolean(entry[1]));
    },
    alertDetails() {
      return {
        class: this.hasError ? 'danger' : 'info',
        message: this.hasError
          ? THROUGHPUT_CHART_STRINGS.ERROR_FETCHING_DATA
          : THROUGHPUT_CHART_STRINGS.NO_DATA,
      };
    },
    singleStatsValues() {
      return [computeMttmData(this.throughputChartData)];
    },
  },
  strings: {
    chartTitle: THROUGHPUT_CHART_STRINGS.CHART_TITLE,
    chartDescription: THROUGHPUT_CHART_STRINGS.CHART_DESCRIPTION,
  },
};
</script>
<template>
  <div>
    <throughput-stats :stats="singleStatsValues" :is-loading="isLoading" />
    <h4 data-testid="chartTitle">{{ $options.strings.chartTitle }}</h4>
    <div class="gl-text-gray-500" data-testid="chartDescription">
      {{ $options.strings.chartDescription }}
    </div>
    <chart-skeleton-loader v-if="isLoading" />
    <gl-area-chart
      v-else-if="chartDataAvailable"
      :data="formattedThroughputChartData"
      :option="chartOptions"
    />
    <gl-alert v-else :variant="alertDetails.class" :dismissible="false" class="gl-mt-4">{{
      alertDetails.message
    }}</gl-alert>
  </div>
</template>
