<script>
import * as Sentry from '@sentry/browser';
import * as DoraApi from 'ee/api/dora_api';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { toYmd } from '~/analytics/shared/utils';
import { createAlert } from '~/flash';
import { s__, sprintf } from '~/locale';
import { SUMMARY_METRICS_REQUEST } from '~/analytics/cycle_analytics/constants';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import DoraChartHeader from './dora_chart_header.vue';
import {
  allChartDefinitions,
  areaChartOptions,
  averageSeriesOptions,
  averageSeriesName,
  chartDescriptionText,
  chartDocumentationHref,
  LAST_WEEK,
  LAST_MONTH,
  LAST_90_DAYS,
  LAST_180_DAYS,
  CHART_TITLE,
} from './static_data/deployment_frequency';
import { apiDataToChartSeries, seriesToAverageSeries } from './util';

const VISIBLE_METRICS = ['deploys', 'deployment-frequency', 'deployment_frequency'];
const filterFn = (data) =>
  data.filter((d) => VISIBLE_METRICS.includes(d.identifier)).map(({ links, ...rest }) => rest);

export default {
  name: 'DeploymentFrequencyCharts',
  components: {
    CiCdAnalyticsCharts,
    DoraChartHeader,
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
      return this.projectPath ? this.projectPath : `groups/${this.groupPath}`;
    },
  },
  async mounted() {
    const results = await Promise.allSettled(
      allChartDefinitions.map(async ({ id, requestParams, startDate, endDate }) => {
        let apiData;
        if (this.projectPath && this.groupPath) {
          throw new Error('Both projectPath and groupPath were provided');
        } else if (this.projectPath) {
          apiData = (
            await DoraApi.getProjectDoraMetrics(
              this.projectPath,
              DoraApi.DEPLOYMENT_FREQUENCY_METRIC_TYPE,
              requestParams,
            )
          ).data;
        } else if (this.groupPath) {
          apiData = (
            await DoraApi.getGroupDoraMetrics(
              this.groupPath,
              DoraApi.DEPLOYMENT_FREQUENCY_METRIC_TYPE,
              requestParams,
            )
          ).data;
        } else {
          throw new Error('Either projectPath or groupPath must be provided');
        }

        const seriesData = apiDataToChartSeries(apiData, startDate, endDate, CHART_TITLE);
        const { data } = seriesData[0];

        this.chartData[id] = [
          ...seriesData,
          {
            ...averageSeriesOptions,
            ...seriesToAverageSeries(
              data,
              sprintf(averageSeriesName, { days: this.$options.chartInDays[id] }),
            ),
          },
        ];
      }),
    );

    const requestErrors = results.filter((r) => r.status === 'rejected').map((r) => r.reason);

    if (requestErrors.length) {
      createAlert({
        message: s__('DORA4Metrics|Something went wrong while getting deployment frequency data.'),
      });

      const allErrorMessages = requestErrors.join('\n');
      Sentry.captureException(
        new Error(
          `Something went wrong while getting deployment frequency data:\n${allErrorMessages}`,
        ),
      );
    }
  },
  methods: {
    getMetricsRequestParams(selectedChart) {
      const {
        requestParams: { start_date },
      } = allChartDefinitions[selectedChart];

      return {
        created_after: toYmd(start_date),
      };
    },
  },

  areaChartOptions,
  chartDescriptionText,
  chartDocumentationHref,
  metricsRequest: SUMMARY_METRICS_REQUEST,
  filterFn,
};
</script>
<template>
  <div data-testid="deployment-frequency-charts">
    <dora-chart-header
      :header-text="s__('DORA4Metrics|Deployment frequency')"
      :chart-description-text="$options.chartDescriptionText"
      :chart-documentation-href="$options.chartDocumentationHref"
    />
    <ci-cd-analytics-charts :charts="charts" :chart-options="$options.areaChartOptions">
      <template #metrics="{ selectedChart }">
        <value-stream-metrics
          :request-path="metricsRequestPath"
          :requests="$options.metricsRequest"
          :request-params="getMetricsRequestParams(selectedChart)"
          :filter-fn="$options.filterFn"
        />
      </template>
    </ci-cd-analytics-charts>
  </div>
</template>
