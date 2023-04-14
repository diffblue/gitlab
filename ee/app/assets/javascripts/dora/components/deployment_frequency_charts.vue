<script>
import * as Sentry from '@sentry/browser';
import { GlToggle, GlBadge } from '@gitlab/ui';
import { gray300 } from '@gitlab/ui/scss_to_js/scss_variables';
import * as DoraApi from 'ee/api/dora_api';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { toYmd } from '~/analytics/shared/utils';
import { linearRegression } from 'ee/analytics/shared/utils';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { spriteIcon } from '~/lib/utils/common_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { nDaysAfter } from '~/lib/utils/datetime_utility';
import { SUMMARY_METRICS_REQUEST } from '~/analytics/cycle_analytics/constants';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import glFeaturesFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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

const TESTING_TERMS_URL = 'https://about.gitlab.com/handbook/legal/testing-agreement/';

export default {
  name: 'DeploymentFrequencyCharts',
  components: {
    CiCdAnalyticsCharts,
    DoraChartHeader,
    ValueStreamMetrics,
    GlToggle,
    GlBadge,
  },
  mixins: [glFeaturesFlagMixin()],
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
  forecastDays: {
    [LAST_WEEK]: 3,
    [LAST_MONTH]: 14,
    [LAST_90_DAYS]: 45,
    [LAST_180_DAYS]: 90,
  },
  i18n: {
    showForecast: s__('DORA4Metrics|Show forecast'),
    forecast: s__('DORA4Metrics|Forecast'),
    badgeTitle: __('Experiment'),
    confirmationTitle: s__('DORA4Metrics|Accept testing terms of use?'),
    confirmationBtnText: s__('DORA4Metrics|Accept testing terms'),
    confirmationHtmlMessage: sprintf(
      s__('DORA4Metrics|By enabling this feature, you accept the %{url}'),
      {
        url: `<a href="${TESTING_TERMS_URL}" target="_blank" rel="noopener noreferrer nofollow">Testing Terms of Use ${spriteIcon(
          'external-link',
          's16',
        )}</a>`,
      },
      false,
    ),
  },
  data() {
    return {
      chartData: {
        [LAST_WEEK]: [],
        [LAST_MONTH]: [],
        [LAST_90_DAYS]: [],
        [LAST_180_DAYS]: [],
      },
      showForecast: false,
      forecastConfirmed: false,
      forecastChartData: {
        [LAST_WEEK]: {},
        [LAST_MONTH]: {},
        [LAST_90_DAYS]: {},
        [LAST_180_DAYS]: {},
      },
    };
  },
  computed: {
    charts() {
      return allChartDefinitions.map((chart) => {
        const data = [...this.chartData[chart.id]];
        if (this.showForecast) {
          data.push(this.forecastChartData[chart.id]);
        }
        return { ...chart, data };
      });
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

        this.forecastChartData[id] = {
          name: this.$options.i18n.forecast,
          data: [],
          lineStyle: { type: 'dashed', color: gray300 },
          areaStyle: { opacity: 0 },
        };

        if (apiData?.length > 0) {
          const { data: forecastedData } = apiDataToChartSeries(
            linearRegression(apiData, this.$options.forecastDays[id]),
            endDate,
            nDaysAfter(endDate, this.$options.forecastDays[id]),
            this.$options.i18n.forecast,
          )[0];

          // Add the last point from the data series so the chart visually joins together
          const lastDataPoint = seriesData[0].data.slice(-1);

          this.forecastChartData[id] = {
            ...this.forecastChartData[id],
            data: [...lastDataPoint, ...forecastedData],
          };
        }
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
    async onToggleForecast(toggleValue) {
      if (toggleValue) {
        await this.confirmForecastTerms();
        if (this.forecastConfirmed) {
          this.showForecast = toggleValue;
        }
      } else {
        this.showForecast = toggleValue;
      }
    },
    async confirmForecastTerms() {
      if (this.forecastConfirmed) return;

      const {
        confirmationTitle: title,
        confirmationBtnText: primaryBtnText,
        confirmationHtmlMessage: modalHtmlMessage,
      } = this.$options.i18n;

      this.forecastConfirmed = await confirmAction('', {
        primaryBtnVariant: 'info',
        primaryBtnText,
        title,
        modalHtmlMessage,
      });
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
      <template v-if="glFeatures.doraChartsForecast" #extend-button-group>
        <div class="gl-display-flex gl-align-items-center">
          <gl-toggle
            :value="showForecast"
            :label="$options.i18n.showForecast"
            label-position="left"
            data-testid="data-forecast-toggle"
            @change="onToggleForecast"
          />
          <gl-badge size="md" variant="info" class="gl-ml-3">{{
            $options.i18n.badgeTitle
          }}</gl-badge>
        </div>
      </template>
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
