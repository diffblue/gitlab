<script>
import * as Sentry from '@sentry/browser';
import { GlToggle, GlBadge, GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { BASE_FORECAST_SERIES_OPTIONS } from 'ee/analytics/shared/constants';
import * as DoraApi from 'ee/api/dora_api';
import SafeHtml from '~/vue_shared/directives/safe_html';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { toYmd } from '~/analytics/shared/utils';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { spriteIcon } from '~/lib/utils/common_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { SUMMARY_METRICS_REQUEST } from '~/analytics/cycle_analytics/constants';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import { DEFAULT_SELECTED_CHART } from '~/vue_shared/components/ci_cd_analytics/constants';
import glFeaturesFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { ERROR_FORECAST_FAILED, ERROR_FORECAST_UNAVAILABLE } from '../graphql/constants';
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
import {
  apiDataToChartSeries,
  seriesToAverageSeries,
  calculateForecast,
  forecastDataToSeries,
} from './util';

const VISIBLE_METRICS = ['deploys', 'deployment-frequency', 'deployment_frequency'];
const filterFn = (data) =>
  data.filter((d) => VISIBLE_METRICS.includes(d.identifier)).map(({ links, ...rest }) => rest);

const TESTING_TERMS_URL = `${PROMO_URL}/handbook/legal/testing-agreement/`;
const FORECAST_FEEDBACK_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/416833';

export default {
  name: 'DeploymentFrequencyCharts',
  components: {
    CiCdAnalyticsCharts,
    DoraChartHeader,
    ValueStreamMetrics,
    GlToggle,
    GlBadge,
    GlAlert,
    GlSprintf,
    GlLink,
  },
  directives: {
    SafeHtml,
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
    contextId: {
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
    forecastUnavailable: s__(
      'DORA4Metrics|The forecast might be inaccurate. To improve it, select a wider time frame or try again when more data is available',
    ),
    forecastFailed: s__(
      'DORA4Metrics|Failed to generate forecast. Try again later. If the problem persists, consider %{linkStart}creating an issue%{linkEnd}.',
    ),
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
    forecastFeedbackText: sprintf(
      s__(
        'DORA4Metrics|To help us improve the Show forecast feature, please share feedback about your experience in %{linkStart}this issue%{linkEnd}.',
      ),
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
        [LAST_WEEK]: [],
        [LAST_MONTH]: [],
        [LAST_90_DAYS]: [],
        [LAST_180_DAYS]: [],
      },
      rawApiData: {
        [LAST_WEEK]: [],
        [LAST_MONTH]: [],
        [LAST_90_DAYS]: [],
        [LAST_180_DAYS]: [],
      },
      selectedChartIndex: DEFAULT_SELECTED_CHART,
      forecastRequestErrorMessage: '',
      forecastError: null,
      isLoading: false,
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
    selectedChartDefinition() {
      return allChartDefinitions[this.selectedChartIndex];
    },
    selectedChartId() {
      return this.selectedChartDefinition.id;
    },
    selectedForecast() {
      return this.forecastChartData[this.selectedChartId];
    },
    selectedDataSeries() {
      return this.chartData[this.selectedChartId][0];
    },
    shouldFetchForecast() {
      return this.showForecast && this.forecastConfirmed && !this.selectedForecast?.data.length;
    },
    forecastHorizon() {
      return this.$options.forecastDays[this.selectedChartId];
    },
    useHoltWintersForecast() {
      return Boolean(this.glFeatures.useHoltWintersForecastForDeploymentFrequency);
    },
    isForecastUnavailableError() {
      return Boolean(this.forecastError === ERROR_FORECAST_UNAVAILABLE);
    },
    alertVariant() {
      return this.isForecastUnavailableError ? 'tip' : 'warning';
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

        this.rawApiData[id] = apiData;
        this.forecastChartData[id] = {
          ...BASE_FORECAST_SERIES_OPTIONS,
          name: this.$options.i18n.forecast,
          data: [],
        };
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
    async onSelectChart(selectedChartIndex) {
      this.selectedChartIndex = selectedChartIndex;
      await this.fetchForecast();
    },
    getMetricsRequestParams(selectedChartIndex) {
      const {
        requestParams: { start_date },
      } = allChartDefinitions[selectedChartIndex];

      return {
        created_after: toYmd(start_date),
      };
    },
    async fetchForecast() {
      if (this.shouldFetchForecast) {
        this.isLoading = true;
        this.forecastError = null;
        const { endDate } = this.selectedChartDefinition;
        const { selectedChartId: id, forecastHorizon, useHoltWintersForecast, contextId } = this;

        try {
          this.forecastRequestErrorMessage = '';

          const forecastData = await calculateForecast({
            contextId,
            forecastHorizon,
            useHoltWintersForecast,
            rawApiData: this.rawApiData[id],
          });

          this.forecastChartData[id].data = forecastDataToSeries({
            forecastData,
            forecastHorizon,
            endDate,
            dataSeries: this.selectedDataSeries.data,
            forecastSeriesLabel: this.$options.i18n.forecast,
          });
        } catch (error) {
          if (error?.message === ERROR_FORECAST_UNAVAILABLE) {
            this.forecastError = ERROR_FORECAST_UNAVAILABLE;
            this.forecastRequestErrorMessage = this.$options.i18n.forecastUnavailable;
          } else {
            this.forecastError = ERROR_FORECAST_FAILED;
            this.forecastRequestErrorMessage = this.$options.i18n.forecastFailed;
          }
        } finally {
          this.isLoading = false;
        }
      }
    },
    async onToggleForecast(toggleValue) {
      if (toggleValue) {
        await this.confirmForecastTerms();
        if (this.forecastConfirmed) {
          this.showForecast = toggleValue;
          await this.fetchForecast();
        }
      } else {
        this.showForecast = toggleValue;
      }
    },
    onDismissAlert() {
      this.forecastRequestErrorMessage = '';
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
  FORECAST_FEEDBACK_ISSUE_URL,
};
</script>
<template>
  <div data-testid="deployment-frequency-charts">
    <dora-chart-header
      :header-text="s__('DORA4Metrics|Deployment frequency')"
      :chart-description-text="$options.chartDescriptionText"
      :chart-documentation-href="$options.chartDocumentationHref"
    />
    <ci-cd-analytics-charts
      :loading="isLoading"
      :charts="charts"
      :chart-options="$options.areaChartOptions"
      @select-chart="onSelectChart"
    >
      <template v-if="glFeatures.doraChartsForecast" #extend-button-group>
        <div class="gl-display-flex gl-align-items-center">
          <gl-toggle
            :value="showForecast"
            :label="$options.i18n.showForecast"
            label-position="left"
            data-testid="data-forecast-toggle"
            @change="onToggleForecast"
          />
          <gl-badge size="md" variant="neutral" class="gl-ml-3">{{
            $options.i18n.badgeTitle
          }}</gl-badge>
        </div>
      </template>
      <template #alerts>
        <gl-alert
          v-if="showForecast"
          class="gl-my-5"
          data-testid="forecast-feedback"
          variant="info"
          :dismissible="false"
        >
          <gl-sprintf :message="$options.i18n.forecastFeedbackText">
            <template #link="{ content }">
              <gl-link
                class="gl-text-decoration-none!"
                :href="$options.FORECAST_FEEDBACK_ISSUE_URL"
                target="_blank"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </gl-alert>
      </template>
      <template #metrics="{ selectedChart }">
        <div>
          <gl-alert
            v-if="forecastRequestErrorMessage.length"
            data-testid="forecast-error"
            :variant="alertVariant"
            @dismiss="onDismissAlert"
          >
            <gl-sprintf v-if="!isForecastUnavailableError" :message="forecastRequestErrorMessage">
              <template #link="{ content }">
                <gl-link
                  class="gl-display-inline-block"
                  :href="$options.FORECAST_FEEDBACK_ISSUE_URL"
                  target="_blank"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
            <template v-else>
              {{ forecastRequestErrorMessage }}
            </template>
          </gl-alert>
          <value-stream-metrics
            :request-path="metricsRequestPath"
            :requests="$options.metricsRequest"
            :request-params="getMetricsRequestParams(selectedChart)"
            :filter-fn="$options.filterFn"
          />
        </div>
      </template>
    </ci-cd-analytics-charts>
  </div>
</template>
