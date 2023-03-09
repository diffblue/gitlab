import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import last180DaysData from 'test_fixtures/api/dora/metrics/daily_time_to_restore_service_for_last_180_days.json';
import lastWeekData from 'test_fixtures/api/dora/metrics/daily_time_to_restore_service_for_last_week.json';
import lastMonthData from 'test_fixtures/api/dora/metrics/daily_time_to_restore_service_for_last_month.json';
import last90DaysData from 'test_fixtures/api/dora/metrics/daily_time_to_restore_service_for_last_90_days.json';
import { useFixturesFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

const makeMockCiCdAnalyticsCharts = ({ selectedChart = 0 } = {}) => ({
  render() {
    return this.$scopedSlots.metrics({
      selectedChart,
    });
  },
});

describe('time_to_restore_service_charts.vue', () => {
  useFixturesFakeDate();

  let TimeToRestoreServiceCharts;
  let DoraChartHeader;

  // Import these components _after_ the date has been set using `useFakeDate`, so
  // that any calls to `new Date()` during module initialization use the fake date
  beforeAll(async () => {
    TimeToRestoreServiceCharts = (
      await import('ee_component/dora/components/time_to_restore_service_charts.vue')
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

  const createComponent = (mountOptions = defaultMountOptions) => {
    wrapper = extendedWrapper(shallowMount(TimeToRestoreServiceCharts, mountOptions));
  };

  const setUpMockTimetoRestoreService = ({ start_date, data }) => {
    mock
      .onGet(/projects\/test%2Fproject\/dora\/metrics/, {
        params: {
          metric: 'time_to_restore_service',
          interval: 'daily',
          per_page: 100,
          end_date: '2015-07-04T00:00:00+0000',
          start_date,
        },
      })
      .replyOnce(HTTP_STATUS_OK, data);
  };

  const findValueStreamMetrics = () => wrapper.findComponent(ValueStreamMetrics);

  afterEach(() => {
    mock.restore();
  });

  describe('when there are no network errors', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      setUpMockTimetoRestoreService({
        start_date: '2015-06-27T00:00:00+0000',
        data: lastWeekData,
      });
      setUpMockTimetoRestoreService({
        start_date: '2015-06-04T00:00:00+0000',
        data: lastMonthData,
      });
      setUpMockTimetoRestoreService({
        start_date: '2015-04-05T00:00:00+0000',
        data: last90DaysData,
      });
      setUpMockTimetoRestoreService({
        start_date: '2015-01-05T00:00:00+0000',
        data: last180DaysData,
      });

      createComponent();

      await axios.waitForAll();
    });

    it('makes 4 GET requests - one for each chart', () => {
      expect(mock.history.get).toHaveLength(4);
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

      it('correctly computes the requestParams', () => {
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
        message: 'Something went wrong while getting time to restore service data.',
      });
    });

    it('reports an error to Sentry', () => {
      expect(captureExceptionSpy).toHaveBeenCalledTimes(1);

      const expectedErrorMessage = [
        'Something went wrong while getting time to restore service data:',
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
        expect(mock.history.get).toHaveLength(4);
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
        expect(mock.history.get).toHaveLength(4);
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
});
