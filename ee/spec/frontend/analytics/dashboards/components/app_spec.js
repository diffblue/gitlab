import { shallowMount } from '@vue/test-utils';
import { createAlert } from '~/flash';
import {
  DASHBOARD_LOADING_FAILURE,
  CHART_LOADING_FAILURE,
} from 'ee/analytics/dashboards/constants';
import Component from 'ee/analytics/dashboards/components/app.vue';
import DoraComparisonTable from 'ee/analytics/dashboards/components/dora_comparison_table.vue';
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

const mockProps = { groupName: 'Exec group', groupFullPath: 'exec-group' };

jest.mock('~/flash');
jest.mock('~/analytics/shared/utils');

describe('Executive dashboard app', () => {
  let wrapper;

  const createWrapper = async ({ props = {} } = {}) => {
    wrapper = shallowMount(Component, {
      propsData: {
        ...mockProps,
        ...props,
      },
    });

    await waitForPromises();
  };

  const findComparisonTable = () => wrapper.findComponent(DoraComparisonTable);
  const getTableData = () => findComparisonTable().props('tableData');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data requests', () => {
    const expectDataRequests = (params) => {
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
        'groups/exec-group',
        params,
      );
    };

    it('will request the metrics for the table data', async () => {
      utils.fetchMetricsData.mockReturnValueOnce({});
      await createWrapper();

      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(MOCK_TABLE_TIME_PERIODS.length);
      MOCK_TABLE_TIME_PERIODS.forEach((timePeriod) =>
        expectDataRequests({
          created_after: timePeriod.start.toISOString(),
          created_before: timePeriod.end.toISOString(),
        }),
      );
    });

    it('will show an alert if the table data failed to load', async () => {
      utils.fetchMetricsData.mockRejectedValueOnce();
      await createWrapper();

      expect(createAlert).toHaveBeenCalledWith({ message: DASHBOARD_LOADING_FAILURE });
    });

    it('will also request the chart data metrics if there is table data', async () => {
      utils.fetchMetricsData.mockReturnValue(mockMonthToDateApiResponse);
      await createWrapper();

      const timePeriods = [...MOCK_TABLE_TIME_PERIODS, ...MOCK_CHART_TIME_PERIODS];
      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(timePeriods.length);
      timePeriods.forEach((timePeriod) =>
        expectDataRequests({
          created_after: timePeriod.start.toISOString(),
          created_before: timePeriod.end.toISOString(),
        }),
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

      expect(createAlert).toHaveBeenCalledWith({ message: CHART_LOADING_FAILURE });
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
  });
});
