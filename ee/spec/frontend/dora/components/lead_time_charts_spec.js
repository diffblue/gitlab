import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import last180DaysData from 'test_fixtures/api/dora/metrics/daily_lead_time_for_changes_for_last_180_days.json';
import lastWeekData from 'test_fixtures/api/dora/metrics/daily_lead_time_for_changes_for_last_week.json';
import lastMonthData from 'test_fixtures/api/dora/metrics/daily_lead_time_for_changes_for_last_month.json';
import last90DaysData from 'test_fixtures/api/dora/metrics/daily_lead_time_for_changes_for_last_90_days.json';
import { useFixturesFakeDate } from 'helpers/fake_date';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('lead_time_charts.vue', () => {
  useFixturesFakeDate();

  let LeadTimeCharts;
  let DoraChartHeader;

  // Import these components _after_ the date has been set using `useFakeDate`, so
  // that any calls to `new Date()` during module initialization use the fake date
  beforeAll(async () => {
    LeadTimeCharts = (await import('ee_component/dora/components/lead_time_charts.vue')).default;
    DoraChartHeader = (await import('ee/dora/components/dora_chart_header.vue')).default;
  });

  let wrapper;
  let mock;
  const defaultMountOptions = {
    provide: {
      projectPath: 'test/project',
    },
    stubs: { GlSprintf },
  };

  const createComponent = ({ mountFn = shallowMount, mountOptions = defaultMountOptions } = {}) => {
    wrapper = mountFn(LeadTimeCharts, mountOptions);
  };

  // Initializes the mock endpoint to return a specific set of lead time data for a given "from" date.
  const setUpMockLeadTime = ({ start_date, data }) => {
    mock
      .onGet(/projects\/test%2Fproject\/dora\/metrics/, {
        params: {
          metric: 'lead_time_for_changes',
          interval: 'daily',
          per_page: 100,
          end_date: '2015-07-04T00:00:00+0000',
          start_date,
        },
      })
      .replyOnce(HTTP_STATUS_OK, data);
  };

  afterEach(() => {
    mock.restore();
  });

  describe('when there are no network errors', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      setUpMockLeadTime({
        start_date: '2015-06-27T00:00:00+0000',
        data: lastWeekData,
      });
      setUpMockLeadTime({
        start_date: '2015-06-04T00:00:00+0000',
        data: lastMonthData,
      });
      setUpMockLeadTime({
        start_date: '2015-04-05T00:00:00+0000',
        data: last90DaysData,
      });
      setUpMockLeadTime({
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
  });

  describe('when there are network errors', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      createComponent();

      await axios.waitForAll();
    });

    it('shows an alert message', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert.mock.calls[0]).toEqual([
        {
          message: 'Something went wrong while getting lead time data.',
          captureError: true,
          error: expect.any(Error),
        },
      ]);
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
          mountOptions: {
            provide: {
              projectPath: 'test/project',
            },
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
          mountOptions: {
            provide: {
              groupPath: 'test/group',
            },
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
          mountOptions: {
            provide: {
              projectPath: 'test/project',
              groupPath: 'test/group',
            },
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
          mountOptions: {
            provide: {},
          },
        });

        await axios.waitForAll();
      });

      it('throws an error (which shows an alert message)', () => {
        expect(createAlert).toHaveBeenCalled();
      });
    });
  });
});
