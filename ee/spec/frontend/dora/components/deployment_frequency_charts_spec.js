import * as Sentry from '@sentry/browser';
import { mount, shallowMount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import { gray300 } from '@gitlab/ui/scss_to_js/scss_variables';
import MockAdapter from 'axios-mock-adapter';
import last180DaysData from 'test_fixtures/api/dora/metrics/daily_deployment_frequency_for_last_180_days.json';
import lastWeekData from 'test_fixtures/api/dora/metrics/daily_deployment_frequency_for_last_week.json';
import lastMonthData from 'test_fixtures/api/dora/metrics/daily_deployment_frequency_for_last_month.json';
import last90DaysData from 'test_fixtures/api/dora/metrics/daily_deployment_frequency_for_last_90_days.json';
import waitForPromises from 'helpers/wait_for_promises';
import { useFixturesFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { createAlert } from '~/alert';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import {
  mockLastWeekData,
  mockLastMonthData,
  mockLast90DaysData,
  mockLast180DaysData,
  mockLastWeekForecastData,
  mockLastMonthForecastData,
  mockLast90DaysForecastData,
  mockLast180DaysForecastData,
} from './mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const makeMockCiCdAnalyticsCharts = ({ selectedChart = 0 } = {}) => ({
  render() {
    return this.$scopedSlots.metrics({
      selectedChart,
    });
  },
});

describe('deployment_frequency_charts.vue', () => {
  useFixturesFakeDate();

  let DeploymentFrequencyCharts;
  let DoraChartHeader;

  // Import these components _after_ the date has been set using `useFakeDate`, so
  // that any calls to `new Date()` during module initialization use the fake date
  beforeAll(async () => {
    DeploymentFrequencyCharts = (
      await import('ee_component/dora/components/deployment_frequency_charts.vue')
    ).default;
    DoraChartHeader = (await import('ee/dora/components/dora_chart_header.vue')).default;
  });

  let wrapper;
  let mock;
  const defaultMountOptions = {
    provide: {
      projectPath: 'test/project',
    },
  };

  const createComponent = (mountOptions = defaultMountOptions, mountFn = shallowMount) => {
    wrapper = extendedWrapper(mountFn(DeploymentFrequencyCharts, mountOptions));
  };

  // Initializes the mock endpoint to return a specific set of deployment
  // frequency data for a given "from" date.
  const setUpMockDeploymentFrequencies = ({ start_date, data }) => {
    mock
      .onGet(/projects\/test%2Fproject\/dora\/metrics/, {
        params: {
          metric: 'deployment_frequency',
          interval: 'daily',
          per_page: 100,
          end_date: '2015-07-04T00:00:00+0000',
          start_date,
        },
      })
      .replyOnce(HTTP_STATUS_OK, data);
  };

  const findValueStreamMetrics = () => wrapper.findComponent(ValueStreamMetrics);
  const findCiCdAnalyticsCharts = () => wrapper.findComponent(CiCdAnalyticsCharts);

  afterEach(() => {
    mock.restore();
  });

  describe('when there are no network errors', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      setUpMockDeploymentFrequencies({
        start_date: '2015-06-27T00:00:00+0000',
        data: lastWeekData,
      });
      setUpMockDeploymentFrequencies({
        start_date: '2015-06-04T00:00:00+0000',
        data: lastMonthData,
      });
      setUpMockDeploymentFrequencies({
        start_date: '2015-04-05T00:00:00+0000',
        data: last90DaysData,
      });
      setUpMockDeploymentFrequencies({
        start_date: '2015-01-05T00:00:00+0000',
        data: last180DaysData,
      });

      createComponent();

      await axios.waitForAll();
    });

    it('makes 4 GET requests - one for each chart', () => {
      expect(mock.history.get).toHaveLength(4);
    });

    it('converts the data from the API into data usable by the chart component', () => {
      expect(findCiCdAnalyticsCharts().props().charts).toMatchSnapshot();
    });

    it('does not show an alert message', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('renders a header', () => {
      expect(wrapper.findComponent(DoraChartHeader).exists()).toBe(true);
    });

    describe('value stream metrics', () => {
      beforeEach(() => {
        createComponent({
          ...defaultMountOptions,
          stubs: {
            CiCdAnalyticsCharts: makeMockCiCdAnalyticsCharts({
              selectedChart: 1,
            }),
          },
        });
      });

      it('renders the value stream metrics component', () => {
        const metricsComponent = findValueStreamMetrics();
        expect(metricsComponent.exists()).toBe(true);
      });

      it('passes the selectedChart correctly and computes the requestParams', () => {
        const metricsComponent = findValueStreamMetrics();
        expect(metricsComponent.props('requestParams')).toMatchObject({
          created_after: '2015-06-04',
        });
      });
    });
  });

  describe('when there are network errors', () => {
    let captureExceptionSpy;
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      createComponent();

      captureExceptionSpy = jest.spyOn(Sentry, 'captureException');

      await axios.waitForAll();
    });

    afterEach(() => {
      captureExceptionSpy.mockRestore();
    });

    it('shows an alert message', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while getting deployment frequency data.',
      });
    });

    it('reports an error to Sentry', () => {
      expect(captureExceptionSpy).toHaveBeenCalledTimes(1);

      const expectedErrorMessage = [
        'Something went wrong while getting deployment frequency data:',
        'Error: Request failed with status code 404',
        'Error: Request failed with status code 404',
        'Error: Request failed with status code 404',
        'Error: Request failed with status code 404',
      ].join('\n');

      expect(captureExceptionSpy).toHaveBeenCalledWith(new Error(expectedErrorMessage));
    });
  });

  describe('group/project behavior', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);

      mock.onGet(/projects\/test%2Fproject\/dora\/metrics/).reply(HTTP_STATUS_OK, lastWeekData);
      mock.onGet(/groups\/test%2Fgroup\/dora\/metrics/).reply(HTTP_STATUS_OK, lastWeekData);
    });

    describe('when projectPath is provided', () => {
      beforeEach(async () => {
        createComponent({
          provide: {
            projectPath: 'test/project',
          },
        });

        await axios.waitForAll();
      });

      it('makes a call to the project API endpoint', () => {
        expect(mock.history.get.length).toBe(4);
        expect(mock.history.get[0].url).toMatch('/projects/test%2Fproject/dora/metrics');
      });

      it('does not throw an error', () => {
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when groupPath is provided', () => {
      beforeEach(async () => {
        createComponent({
          provide: {
            groupPath: 'test/group',
          },
        });

        await axios.waitForAll();
      });

      it('makes a call to the group API endpoint', () => {
        expect(mock.history.get.length).toBe(4);
        expect(mock.history.get[0].url).toMatch('/groups/test%2Fgroup/dora/metrics');
      });

      it('does not throw an error', () => {
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when both projectPath and groupPath are provided', () => {
      beforeEach(async () => {
        createComponent({
          provide: {
            projectPath: 'test/project',
            groupPath: 'test/group',
          },
        });

        await axios.waitForAll();
      });

      it('throws an error (which shows an alert message)', () => {
        expect(createAlert).toHaveBeenCalled();
      });
    });

    describe('when neither projectPath nor groupPath are provided', () => {
      beforeEach(async () => {
        createComponent({
          provide: {},
        });

        await axios.waitForAll();
      });

      it('throws an error (which shows an alert message)', () => {
        expect(createAlert).toHaveBeenCalled();
      });
    });
  });

  describe('with doraChartsForecast=true', () => {
    const mountOpts = {
      provide: {
        projectPath: 'test/project',
        glFeatures: {
          doraChartsForecast: true,
        },
      },
    };

    const findDataForecastToggle = () => wrapper.findByTestId('data-forecast-toggle');
    const findExperimentBadge = () => wrapper.findComponent(GlBadge);
    const getChartData = () => findCiCdAnalyticsCharts().props().charts;

    async function toggleDataForecast(confirmationValue = true) {
      confirmAction.mockResolvedValueOnce(confirmationValue);

      await findDataForecastToggle().vm.$emit('change', !findDataForecastToggle().props('value'));
      await waitForPromises();
    }

    beforeEach(async () => {
      mock = new MockAdapter(axios);
      window.gon = { features: { doraChartsForecast: true } };

      setUpMockDeploymentFrequencies({
        start_date: '2015-06-27T00:00:00+0000',
        data: lastWeekData,
      });
      setUpMockDeploymentFrequencies({
        start_date: '2015-06-04T00:00:00+0000',
        data: lastMonthData,
      });
      setUpMockDeploymentFrequencies({
        start_date: '2015-04-05T00:00:00+0000',
        data: last90DaysData,
      });
      setUpMockDeploymentFrequencies({
        start_date: '2015-01-05T00:00:00+0000',
        data: last180DaysData,
      });

      createComponent(mountOpts, mount);
      await axios.waitForAll();
    });

    it('renders the "Experiment" badge', () => {
      expect(findExperimentBadge().html()).toHaveText(DeploymentFrequencyCharts.i18n.badgeTitle);
    });

    it.each`
      timePeriod         | chartDataIndex | result
      ${'Last week'}     | ${0}           | ${mockLastWeekData}
      ${'Last month'}    | ${1}           | ${mockLastMonthData}
      ${'Last 90 days'}  | ${2}           | ${mockLast90DaysData}
      ${'Last 180 days'} | ${3}           | ${mockLast180DaysData}
    `('does not calculate a forecast for $timePeriod by default', ({ chartDataIndex, result }) => {
      const currentTimePeriodChartData = getChartData()[chartDataIndex];
      const dataSeries = currentTimePeriodChartData.data[0];

      expect(currentTimePeriodChartData.data).toHaveLength(2);
      expect(dataSeries.data).toEqual(result);
    });

    describe('Show forecast toggle', () => {
      afterEach(() => {
        confirmAction.mockReset();
      });

      it('renders the forecast toggle', () => {
        expect(findDataForecastToggle().exists()).toBe(true);
      });

      it('displays the testing terms confirmation', async () => {
        await toggleDataForecast();

        expect(confirmAction).toHaveBeenCalledWith('', {
          primaryBtnText: DeploymentFrequencyCharts.i18n.confirmationBtnText,
          primaryBtnVariant: 'info',
          title: DeploymentFrequencyCharts.i18n.confirmationTitle,
          modalHtmlMessage: DeploymentFrequencyCharts.i18n.confirmationHtmlMessage,
        });
      });

      it('does not show the terms confirmation once accepted', async () => {
        await toggleDataForecast(); // on with confirmation
        await toggleDataForecast(); // off
        await toggleDataForecast(); // on skip confirmation

        expect(confirmAction).toHaveBeenCalledTimes(1);
      });

      it.each`
        timePeriod         | chartDataIndex | daysForecasted | result
        ${'Last week'}     | ${0}           | ${4}           | ${mockLastWeekForecastData}
        ${'Last month'}    | ${1}           | ${15}          | ${mockLastMonthForecastData}
        ${'Last 90 days'}  | ${2}           | ${46}          | ${mockLast90DaysForecastData}
        ${'Last 180 days'} | ${3}           | ${91}          | ${mockLast180DaysForecastData}
      `(
        'Calculates the forecasted data for $timePeriod',
        async ({ chartDataIndex, result, daysForecasted }) => {
          await toggleDataForecast();

          const currentTimePeriodChartData = getChartData()[chartDataIndex];
          const forecastSeries = currentTimePeriodChartData.data[2];

          expect(currentTimePeriodChartData.data).toHaveLength(3);
          expect(forecastSeries.data).toEqual(result);
          expect(forecastSeries.data.length).toBe(daysForecasted);
          expect(forecastSeries.lineStyle).toEqual({ type: 'dashed', color: gray300 });
          expect(forecastSeries.areaStyle).toEqual({ opacity: 0 });
        },
      );

      it('no change when the confirmation is cancelled', async () => {
        await toggleDataForecast(false);

        expect(findDataForecastToggle().props().value).toBe(false);
      });
    });
  });
});
