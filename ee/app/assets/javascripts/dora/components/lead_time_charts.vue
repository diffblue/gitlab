<script>
import * as DoraApi from 'ee/api/dora_api';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import { buildNullSeries } from '../../analytics/shared/utils';
import ChartTooltipText from '../../analytics/shared/components/chart_tooltip_text.vue';
import DoraChartHeader from './dora_chart_header.vue';
import {
  allChartDefinitions,
  areaChartOptions,
  averageSeriesOptions,
  medianSeriesTitle,
  chartDescriptionText,
  chartDocumentationHref,
  LAST_WEEK,
  LAST_MONTH,
  LAST_90_DAYS,
  LAST_180_DAYS,
  CHART_TITLE,
  NO_DATA_MESSAGE,
} from './static_data/lead_time';
import { apiDataToChartSeries, seriesToMedianSeries, extractTimeSeriesTooltip } from './util';

export default {
  name: 'LeadTimeCharts',
  components: {
    CiCdAnalyticsCharts,
    DoraChartHeader,
    ChartTooltipText,
  },
  inject: {
    projectPath: {
      type: String,
      default: '',
    },
    groupPath: {
      type: String,
      default: '',
    },
  },
  chartInDays: {
    [LAST_WEEK]: 7,
    [LAST_MONTH]: 30,
    [LAST_90_DAYS]: 90,
    [LAST_180_DAYS]: 180,
  },
  data() {
    return {
      chartData: {
        [LAST_WEEK]: [],
        [LAST_MONTH]: [],
        [LAST_90_DAYS]: [],
        [LAST_180_DAYS]: [],
      },
      tooltipTitle: null,
      tooltipValue: null,
    };
  },
  computed: {
    charts() {
      return allChartDefinitions.map((chart) => ({
        ...chart,
        data: this.chartData[chart.id],
      }));
    },
  },
  async mounted() {
    if (!this.checkProvidedPaths()) {
      return;
    }

    const results = await Promise.allSettled(
      allChartDefinitions.map(async ({ id, requestParams, startDate, endDate }) => {
        const { data: apiData } = this.projectPath
          ? await DoraApi.getProjectDoraMetrics(
              this.projectPath,
              DoraApi.LEAD_TIME_FOR_CHANGES,
              requestParams,
            )
          : await DoraApi.getGroupDoraMetrics(
              this.groupPath,
              DoraApi.LEAD_TIME_FOR_CHANGES,
              requestParams,
            );

        const seriesData = apiDataToChartSeries(apiData, startDate, endDate, CHART_TITLE, null);
        const nullSeries = buildNullSeries({
          seriesData,
          nullSeriesTitle: this.$options.i18n.noMergeRequestsDeployed,
        });

        const { data } = seriesData[0];
        const medianSeries = {
          ...averageSeriesOptions,
          ...seriesToMedianSeries(
            data,
            sprintf(medianSeriesTitle, { days: this.$options.chartInDays[id] }),
          ),
        };

        this.chartData[id] = [nullSeries[1], medianSeries, nullSeries[0]];
      }),
    );

    const requestErrors = results.filter((r) => r.status === 'rejected').map((r) => r.reason);

    if (requestErrors.length) {
      const allErrorMessages = requestErrors.join('\n');

      createAlert({
        message: this.$options.i18n.alertMessage,
        error: new Error(`Something went wrong while getting lead time data:\n${allErrorMessages}`),
        captureError: true,
      });
    }
  },
  methods: {
    formatTooltipText(params) {
      const { tooltipTitle, tooltipValue } = extractTimeSeriesTooltip(params, this.medianLeadTime);
      this.tooltipTitle = tooltipTitle;
      this.tooltipValue = tooltipValue;
    },
    /**
     * Validates that exactly one of [this.projectPath, this.groupPath] has been
     * provided to this component. If not, an alert message is shown and an error
     * is logged with Sentry. This is mainly intended to be a development aid.

     * @returns {Boolean} Whether or not the paths are valid
     */
    checkProvidedPaths() {
      let errorMessage = '';

      if (this.projectPath && this.groupPath) {
        errorMessage = 'Both projectPath and groupPath were provided';
      }

      if (!this.projectPath && !this.groupPath) {
        errorMessage = 'Either projectPath or groupPath must be provided';
      }

      if (errorMessage) {
        createAlert({
          message: this.$options.i18n.alertMessage,
          error: new Error(`Error while rendering lead time charts: ${errorMessage}`),
          captureError: true,
        });

        return false;
      }

      return true;
    },
  },
  areaChartOptions,
  chartDescriptionText,
  chartDocumentationHref,
  i18n: {
    alertMessage: s__('DORA4Metrics|Something went wrong while getting lead time data.'),
    chartHeaderText: CHART_TITLE,
    medianLeadTime: CHART_TITLE,
    noMergeRequestsDeployed: NO_DATA_MESSAGE,
  },
};
</script>
<template>
  <div data-testid="lead-time-charts">
    <dora-chart-header
      :header-text="$options.i18n.chartHeaderText"
      :chart-description-text="$options.chartDescriptionText"
      :chart-documentation-href="$options.chartDocumentationHref"
    />

    <!-- Using renderer="canvas" here, otherwise the area chart coloring doesn't work if the
         first value in the series is `null`. This appears to have been fixed in ECharts v5,
         so once we upgrade, we can go back to using the default renderer (SVG). -->
    <ci-cd-analytics-charts
      :charts="charts"
      :chart-options="$options.areaChartOptions"
      :format-tooltip-text="formatTooltipText"
      renderer="canvas"
    >
      <template #tooltip-title> {{ tooltipTitle }} </template>
      <template #tooltip-content>
        <chart-tooltip-text
          :empty-value-text="$options.i18n.noMergeRequestsDeployed"
          :tooltip-value="tooltipValue"
        />
      </template>
    </ci-cd-analytics-charts>
  </div>
</template>
