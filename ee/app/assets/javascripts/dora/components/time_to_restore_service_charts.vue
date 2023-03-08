<script>
import * as Sentry from '@sentry/browser';
import * as DoraApi from 'ee/api/dora_api';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { toYmd } from '~/analytics/shared/utils';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import { METRICS_REQUESTS } from '~/analytics/cycle_analytics/constants';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import { buildNullSeries } from '../../analytics/shared/utils';
import ChartTooltipText from '../../analytics/shared/components/chart_tooltip_text.vue';
import DoraChartHeader from './dora_chart_header.vue';
import {
  allChartDefinitions,
  areaChartOptions,
  averageSeriesOptions,
  medianSeriesName,
  chartDescriptionText,
  chartDocumentationHref,
  LAST_WEEK,
  LAST_MONTH,
  LAST_90_DAYS,
  LAST_180_DAYS,
  CHART_TITLE,
} from './static_data/time_to_restore_service';
import { apiDataToChartSeries, seriesToMedianSeries, extractTimeSeriesTooltip } from './util';

const VISIBLE_METRICS = [DoraApi.TIME_TO_RESTORE_SERVICE];

// The metrics API endpoint returns a few different types of metrics, we only want time to restore here
const extractTimeToRestoreServiceMetrics = (data) =>
  data.filter((d) => VISIBLE_METRICS.includes(d.identifier)).map(({ links, ...rest }) => rest);

export default {
  name: 'TimeToRestoreServiceCharts',
  components: {
    CiCdAnalyticsCharts,
    DoraChartHeader,
    ChartTooltipText,
    ValueStreamMetrics,
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
    metricsRequestPath() {
      return this.projectPath || `groups/${this.groupPath}`;
    },
  },
  async mounted() {
    try {
      await this.getChartData();
    } catch (error) {
      createAlert({
        message: s__(
          'DORA4Metrics|Something went wrong while getting time to restore service data.',
        ),
      });

      Sentry.captureException(
        new Error(
          `Something went wrong while getting time to restore service data:\n${error.message}`,
        ),
      );
    }
  },
  methods: {
    async getChartData() {
      if (this.projectPath && this.groupPath) {
        throw new Error('Both projectPath and groupPath were provided');
      }

      const requestPath = this.projectPath || this.groupPath;

      if (!requestPath) {
        throw new Error('Either projectPath or groupPath must be provided');
      }

      const getDoraMetrics = this.projectPath
        ? DoraApi.getProjectDoraMetrics
        : DoraApi.getGroupDoraMetrics;

      const results = await Promise.allSettled(
        allChartDefinitions.map(async ({ id, requestParams, startDate, endDate }) => {
          const { data: apiData } = await getDoraMetrics(
            requestPath,
            DoraApi.TIME_TO_RESTORE_SERVICE,
            requestParams,
          );

          const seriesData = apiDataToChartSeries(apiData, startDate, endDate, CHART_TITLE, null);
          const nullSeries = buildNullSeries({
            seriesData,
            nullSeriesTitle: this.$options.i18n.noIncidents,
          });
          const { data } = seriesData[0];

          const medianSeries = {
            ...averageSeriesOptions,
            ...seriesToMedianSeries(
              data,
              sprintf(medianSeriesName, { days: this.$options.chartInDays[id] }),
            ),
          };

          this.chartData[id] = [nullSeries[1], medianSeries, nullSeries[0]];
        }),
      );

      const requestErrors = results.filter((r) => r.status === 'rejected').map((r) => r.reason);

      if (requestErrors.length) {
        const allErrorMessages = requestErrors.join('\n');
        throw new Error(allErrorMessages);
      }
    },
    getMetricsRequestParams(selectedChart) {
      const {
        requestParams: { start_date },
      } = allChartDefinitions[selectedChart];

      return {
        created_after: toYmd(start_date),
      };
    },
    formatTooltipText(params) {
      const { tooltipTitle, tooltipValue } = extractTimeSeriesTooltip(params, CHART_TITLE);
      this.tooltipTitle = tooltipTitle;
      this.tooltipValue = tooltipValue;
    },
  },
  areaChartOptions,
  chartDescriptionText,
  chartDocumentationHref,
  metricsRequest: METRICS_REQUESTS,
  extractTimeToRestoreServiceMetrics,
  i18n: {
    noIncidents: s__('DORA4Metrics|No incidents during this period'),
  },
};
</script>
<template>
  <div data-testid="time-to-restore-service-charts">
    <dora-chart-header
      :header-text="s__('DORA4Metrics|Time to restore service')"
      :chart-description-text="$options.chartDescriptionText"
      :chart-documentation-href="$options.chartDocumentationHref"
    />
    <ci-cd-analytics-charts
      :charts="charts"
      :chart-options="$options.areaChartOptions"
      :format-tooltip-text="formatTooltipText"
    >
      <template #metrics="{ selectedChart }">
        <value-stream-metrics
          :request-path="metricsRequestPath"
          :requests="$options.metricsRequest"
          :request-params="getMetricsRequestParams(selectedChart)"
          :filter-fn="$options.extractTimeToRestoreServiceMetrics"
        />
      </template>
      <template #tooltip-title> {{ tooltipTitle }} </template>
      <template #tooltip-content>
        <chart-tooltip-text
          :empty-value-text="$options.i18n.noIncidents"
          :tooltip-value="tooltipValue"
        />
      </template>
    </ci-cd-analytics-charts>
  </div>
</template>
