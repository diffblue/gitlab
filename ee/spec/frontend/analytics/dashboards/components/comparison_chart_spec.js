import { shallowMount } from '@vue/test-utils';
import { createAlert } from '~/alert';
import {
  DASHBOARD_LOADING_FAILURE,
  CHART_LOADING_FAILURE,
} from 'ee/analytics/dashboards/constants';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import ComparisonTable from 'ee/analytics/dashboards/components/comparison_table.vue';
import * as utils from '~/analytics/shared/utils';
import waitForPromises from 'helpers/wait_for_promises';
import {
  MOCK_TABLE_TIME_PERIODS,
  MOCK_CHART_TIME_PERIODS,
  mockMonthToDateApiResponse,
  mockPreviousMonthApiResponse,
  mockTwoMonthsAgoApiResponse,
  mockThreeMonthsAgoApiResponse,
  mockComparativeTableData,
} from '../mock_data';

const mockProps = { name: 'Exec group', requestPath: 'exec-group', isProject: false };

jest.mock('~/alert');
jest.mock('~/analytics/shared/utils');

describe('Comparison chart', () => {
  let wrapper;

  const createWrapper = async ({ props = {} } = {}) => {
    wrapper = shallowMount(ComparisonChart, {
      propsData: {
        ...mockProps,
        ...props,
      },
    });

    await waitForPromises();
  };

  const findComparisonTable = () => wrapper.findComponent(ComparisonTable);
  const getTableData = () => findComparisonTable().props('tableData');

  const expectDataRequests = (params, requestPath = '') => {
    expect(utils.fetchMetricsData).toHaveBeenCalledWith(
      [
        expect.objectContaining({
          endpoint: 'time_summary',
          name: 'time summary',
        }),
        expect.objectContaining({
          endpoint: 'summary',
          name: 'recent activity',
        }),
      ],
      requestPath,
      params,
    );
  };

  describe('data requests', () => {
    it('will request the metrics for the table data', async () => {
      utils.fetchMetricsData.mockReturnValueOnce({});
      await createWrapper();

      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(MOCK_TABLE_TIME_PERIODS.length);
      MOCK_TABLE_TIME_PERIODS.forEach((timePeriod) =>
        expectDataRequests(
          {
            created_after: timePeriod.start.toISOString(),
            created_before: timePeriod.end.toISOString(),
          },
          'groups/exec-group',
        ),
      );
    });

    it('will show an alert if the table data failed to load', async () => {
      utils.fetchMetricsData.mockRejectedValueOnce();
      await createWrapper();

      expect(createAlert).toHaveBeenCalledWith({
        message: DASHBOARD_LOADING_FAILURE,
        captureError: true,
      });
    });

    it('will also request the chart data metrics if there is table data', async () => {
      utils.fetchMetricsData.mockReturnValue(mockMonthToDateApiResponse);
      await createWrapper();

      const timePeriods = [...MOCK_TABLE_TIME_PERIODS, ...MOCK_CHART_TIME_PERIODS];
      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(timePeriods.length);
      timePeriods.forEach((timePeriod) =>
        expectDataRequests(
          {
            created_after: timePeriod.start.toISOString(),
            created_before: timePeriod.end.toISOString(),
          },
          'groups/exec-group',
        ),
      );
    });

    it('will show an alert if the chart data failed to load', async () => {
      utils.fetchMetricsData
        .mockReturnValueOnce(mockMonthToDateApiResponse)
        .mockReturnValueOnce(mockPreviousMonthApiResponse)
        .mockReturnValueOnce(mockTwoMonthsAgoApiResponse)
        .mockReturnValueOnce(mockThreeMonthsAgoApiResponse)
        .mockRejectedValueOnce();
      await createWrapper();

      expect(createAlert).toHaveBeenCalledWith({
        message: CHART_LOADING_FAILURE,
        captureError: true,
      });
    });
  });

  describe('table data', () => {
    it('renders a message when theres no data', async () => {
      utils.fetchMetricsData.mockReturnValueOnce({});
      await createWrapper();

      expect(wrapper.text()).toContain('No data available');
    });

    it('renders each DORA metric when there is table data', async () => {
      utils.fetchMetricsData
        .mockReturnValueOnce(mockMonthToDateApiResponse)
        .mockReturnValueOnce(mockPreviousMonthApiResponse)
        .mockReturnValueOnce(mockTwoMonthsAgoApiResponse)
        .mockReturnValueOnce(mockThreeMonthsAgoApiResponse);
      await createWrapper();

      const metricNames = getTableData().map(({ metric }) => metric);
      expect(metricNames).toEqual(mockComparativeTableData.map(({ metric }) => metric));
    });

    it('renders a chart on each row', async () => {
      utils.fetchMetricsData.mockReturnValue(mockMonthToDateApiResponse);
      await createWrapper();

      expect(getTableData().filter(({ chart }) => !chart)).toEqual([]);
    });

    it('renders the group title', async () => {
      await createWrapper();

      expect(wrapper.text()).toContain('Metrics comparison for Exec group group');
    });
  });

  describe('with isProject=true', () => {
    const fakeProjectPath = 'fake/project/path';

    beforeEach(async () => {
      utils.fetchMetricsData
        .mockReturnValueOnce(mockMonthToDateApiResponse)
        .mockReturnValueOnce(mockPreviousMonthApiResponse)
        .mockReturnValueOnce(mockTwoMonthsAgoApiResponse)
        .mockReturnValueOnce(mockThreeMonthsAgoApiResponse);

      await createWrapper({ props: { isProject: true, requestPath: fakeProjectPath } });
    });

    it('renders the project title', () => {
      expect(wrapper.text()).toContain('Metrics comparison for Exec group project');
    });

    it('will request project endpoints for the summary and time summary metrics', () => {
      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(10);

      MOCK_TABLE_TIME_PERIODS.forEach((timePeriod) =>
        expectDataRequests(
          {
            created_after: timePeriod.start.toISOString(),
            created_before: timePeriod.end.toISOString(),
          },
          fakeProjectPath,
        ),
      );
    });
  });
});
