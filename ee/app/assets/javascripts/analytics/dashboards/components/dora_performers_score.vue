<script>
import { GlStackedColumnChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { GlCard, GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { sprintf, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import getGroupOrProject from 'ee/analytics/dashboards/graphql/get_group_or_project.query.graphql';
import groupDoraPerformanceScoreCountsQuery from 'ee/analytics/dashboards/graphql/group_dora_performance_score_counts.query.graphql';
import { extractDoraPerformanceScoreCounts } from 'ee/analytics/dashboards/api';
import {
  DORA_PERFORMERS_SCORE_METRICS,
  DORA_PERFORMERS_SCORE_DEFAULT_PANEL_TITLE,
  DORA_PERFORMERS_SCORE_PANEL_TITLE_WITH_PROJECTS_COUNT,
  DORA_PERFORMERS_SCORE_TOOLTIP_PROJECTS_COUNT_TITLE,
  DORA_PERFORMERS_SCORE_NOT_INCLUDED,
  DORA_PERFORMERS_SCORE_LOADING_ERROR,
  DORA_PERFORMERS_SCORE_PROJECT_NAMESPACE_ERROR,
  DORA_PERFORMERS_SCORE_CHART_COLOR_PALETTE,
  DORA_PERFORMERS_SCORE_NO_DATA,
} from 'ee/analytics/dashboards/constants';

export default {
  name: 'DoraPerformersScore',
  components: {
    GlCard,
    GlStackedColumnChart,
    GlChartSeriesLabel,
    ChartSkeletonLoader,
    GlSkeletonLoader,
    GlAlert,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      chart: null,
      hasDoraPerformanceScoresFetchError: false,
      tooltip: {
        projectsCountTitle: null,
        metricTitle: null,
        scores: [],
        scoreDefinition: null,
      },
    };
  },
  apollo: {
    groupOrProject: {
      query: getGroupOrProject,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      skip() {
        return !this.fullPath || !this.shouldDisplayPanel;
      },
      update(data) {
        return data;
      },
    },
    groupDoraPerformanceScoreCounts: {
      query: groupDoraPerformanceScoreCountsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      skip() {
        return !this.fullPath || !this.shouldDisplayPanel || this.isProjectNamespace;
      },
      update(data) {
        const { namespace } = data;

        return {
          projectsCount: namespace?.projects?.count ?? null,
          items: namespace?.doraPerformanceScoreCounts?.nodes ?? [],
        };
      },
      error() {
        this.hasDoraPerformanceScoresFetchError = true;
      },
    },
  },
  computed: {
    fullPath() {
      return this.data?.namespace;
    },
    isLoading() {
      return (
        this.$apollo.queries.groupOrProject.loading ||
        this.$apollo.queries.groupDoraPerformanceScoreCounts.loading
      );
    },
    namespace() {
      return this.groupOrProject?.group ?? this.groupOrProject?.project;
    },
    isProjectNamespace() {
      // eslint-disable-next-line no-underscore-dangle
      return this.namespace?.__typename === TYPENAME_PROJECT;
    },
    chartData() {
      return extractDoraPerformanceScoreCounts(this.groupDoraPerformanceScoreCounts?.items);
    },
    doraMetrics() {
      return DORA_PERFORMERS_SCORE_METRICS.map(({ label }) => label);
    },
    shouldDisplayDefaultPanelTitle() {
      return !this.namespace || this.isProjectNamespace || this.hasDoraPerformanceScoresFetchError;
    },
    panelTitle() {
      if (this.shouldDisplayDefaultPanelTitle) {
        return this.$options.i18n.defaultPanelTitle;
      }

      const projectsCount = this.groupDoraPerformanceScoreCounts?.projectsCount ?? 0;

      return sprintf(this.$options.i18n.panelTitleWithProjectsCount, {
        groupName: this.namespace?.name,
        count: projectsCount,
      });
    },
    errorMessage() {
      if (!this.namespace || this.hasDoraPerformanceScoresFetchError) {
        return sprintf(this.$options.i18n.loadingError, {
          fullPath: this.fullPath,
        });
      }

      if (this.isProjectNamespace) {
        return this.$options.i18n.projectNamespaceError;
      }

      return '';
    },
    hasData() {
      return this.chartData.some(({ data }) => data.some((val) => val));
    },
    noDataMessage() {
      return sprintf(this.$options.i18n.noData, {
        fullPath: this.fullPath,
      });
    },
    tooltipTitle() {
      const { metricTitle, projectsCountTitle } = this.tooltip;

      if (projectsCountTitle) {
        return projectsCountTitle;
      }

      return metricTitle;
    },
    shouldDisplayPanel() {
      return this.glFeatures?.doraPerformersScorePanel;
    },
  },
  beforeDestroy() {
    if (this.chart) {
      this.chart.off('mouseover', this.onChartDataSeriesMouseOver);
      this.chart.off('mouseout', this.onChartDataSeriesMouseOut);
    }
  },
  methods: {
    onChartCreated(chart) {
      this.chart = chart;

      this.chart.on('mouseover', 'series', this.onChartDataSeriesMouseOver);
      this.chart.on('mouseout', 'series', this.onChartDataSeriesMouseOut);
    },
    onChartDataSeriesMouseOver({ dataIndex, seriesIndex, value }) {
      const scoreDefinition =
        this.getScoreDefinition(dataIndex, seriesIndex) ??
        this.$options.i18n.notIncludedScoreDefinition(value);
      const projectsCountTitle = this.$options.i18n.tooltipProjectsCountTitle(value);

      this.tooltip = {
        ...this.tooltip,
        projectsCountTitle,
        scoreDefinition,
      };
    },
    onChartDataSeriesMouseOut() {
      this.tooltip = { ...this.tooltip, projectsCountTitle: null, scoreDefinition: null };
    },
    getScoreDefinition(dataIndex, seriesIndex) {
      return DORA_PERFORMERS_SCORE_METRICS[dataIndex].scoreDefinitions[seriesIndex];
    },
    formatTooltipText({ value: metricTitle, seriesData }) {
      const scores = seriesData.map(({ seriesId, seriesName, seriesIndex, value }) => ({
        seriesId,
        seriesName,
        color: this.$options.customPalette[seriesIndex],
        value: value ?? this.$options.i18n.noTooltipData,
      }));

      this.tooltip = {
        ...this.tooltip,
        metricTitle,
        scores,
      };
    },
  },
  i18n: {
    noData: DORA_PERFORMERS_SCORE_NO_DATA,
    noTooltipData: __('No data'),
    loadingError: DORA_PERFORMERS_SCORE_LOADING_ERROR,
    projectNamespaceError: DORA_PERFORMERS_SCORE_PROJECT_NAMESPACE_ERROR,
    defaultPanelTitle: DORA_PERFORMERS_SCORE_DEFAULT_PANEL_TITLE,
    panelTitleWithProjectsCount: DORA_PERFORMERS_SCORE_PANEL_TITLE_WITH_PROJECTS_COUNT,
    notIncludedScoreDefinition: DORA_PERFORMERS_SCORE_NOT_INCLUDED,
    tooltipProjectsCountTitle: DORA_PERFORMERS_SCORE_TOOLTIP_PROJECTS_COUNT_TITLE,
  },
  customPalette: DORA_PERFORMERS_SCORE_CHART_COLOR_PALETTE,
  presentation: 'tiled',
  xAxisTitle: '',
  yAxisTitle: '',
  xAxisType: 'category',
  chartOptions: {
    yAxis: [
      {
        axisLabel: {
          formatter: (value) => value,
        },
      },
    ],
  },
};
</script>

<template>
  <gl-card
    v-if="shouldDisplayPanel"
    data-testid="dora-performers-score-panel"
    header-class="gl-bg-transparent gl-border-none"
    :body-class="['gl-pt-0', { 'gl-px-0': !errorMessage }]"
  >
    <template #header>
      <gl-skeleton-loader v-if="isLoading" :lines="1" :width="450" />
      <h5 v-else data-testid="dora-performers-score-panel-title" class="gl-my-0">
        {{ panelTitle }}
      </h5>
    </template>

    <chart-skeleton-loader v-if="isLoading" />

    <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>

    <div v-else-if="!hasData" class="gl-text-center gl-text-secondary">
      {{ noDataMessage }}
    </div>

    <gl-stacked-column-chart
      v-else
      :bars="chartData"
      :group-by="doraMetrics"
      :option="$options.chartOptions"
      :presentation="$options.presentation"
      :custom-palette="$options.customPalette"
      :x-axis-type="$options.xAxisType"
      :x-axis-title="$options.xAxisTitle"
      :y-axis-title="$options.yAxisTitle"
      :format-tooltip-text="formatTooltipText"
      responsive
      @created="onChartCreated"
    >
      <template #tooltip-title>{{ tooltipTitle }}</template>
      <template #tooltip-content>
        <div v-if="tooltip.scoreDefinition" class="gl-max-w-26">{{ tooltip.scoreDefinition }}</div>
        <template v-else>
          <div
            v-for="{ seriesId, seriesName, color, value } in tooltip.scores"
            :key="seriesId"
            class="gl-display-flex gl-justify-content-space-between gl-line-height-24 gl-min-w-20"
          >
            <gl-chart-series-label class="gl-mr-7 gl-font-sm" :color="color">
              {{ seriesName }}
            </gl-chart-series-label>
            <div>{{ value }}</div>
          </div>
        </template>
      </template>
    </gl-stacked-column-chart>
  </gl-card>
</template>
