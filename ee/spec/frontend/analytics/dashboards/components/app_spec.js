import { shallowMount } from '@vue/test-utils';
import {
  THIS_MONTH,
  LAST_MONTH,
  TWO_MONTHS_AGO,
  THREE_MONTHS_AGO,
} from 'ee/analytics/dashboards/constants';
import Component from 'ee/analytics/dashboards/components/app.vue';
import DoraComparisonTable from 'ee/analytics/dashboards/components/dora_comparison_table.vue';
import * as utils from '~/analytics/shared/utils';
import {
  mockMonthToDateApiResponse,
  mockPreviousMonthApiResponse,
  mockTwoMonthsAgoApiResponse,
  mockThreeMonthsAgoApiResponse,
} from '../mock_data';

const mockProps = { groupName: 'Exec group', groupFullPath: 'exec-group' };

jest.mock('~/analytics/shared/utils');

describe('Executive dashboard app', () => {
  let wrapper;

  function createComponent({ props = {} } = {}) {
    return shallowMount(Component, {
      propsData: {
        ...mockProps,
        ...props,
      },
    });
  }

  const findComparisonTable = () => wrapper.findComponent(DoraComparisonTable);
  const getTableData = () => findComparisonTable().props('data');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data requests', () => {
    beforeEach(async () => {
      wrapper = await createComponent();
    });

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

    it('will request the summary and time summary metrics for all time periods', () => {
      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(4);

      [THIS_MONTH, LAST_MONTH, TWO_MONTHS_AGO, THREE_MONTHS_AGO].forEach((timePeriod) =>
        expectDataRequests({
          created_after: timePeriod.start.toISOString(),
          created_before: timePeriod.end.toISOString(),
        }),
      );
    });
  });

  describe('no data', () => {
    beforeEach(async () => {
      utils.fetchMetricsData.mockReturnValueOnce({});

      wrapper = await createComponent();
    });

    it('renders the no data message', () => {
      expect(wrapper.text()).toContain('No data available');
    });
  });

  describe('with data', () => {
    beforeEach(async () => {
      utils.fetchMetricsData
        .mockReturnValueOnce(mockMonthToDateApiResponse)
        .mockReturnValueOnce(mockPreviousMonthApiResponse)
        .mockReturnValueOnce(mockTwoMonthsAgoApiResponse)
        .mockReturnValueOnce(mockThreeMonthsAgoApiResponse);

      wrapper = await createComponent();
    });

    it('renders each DORA metric', () => {
      const metricNames = getTableData().map(({ metric }) => metric);

      expect(metricNames).toEqual([
        { value: 'Deployment Frequency' },
        { value: 'Lead Time for Changes' },
        { value: 'Time to Restore Service' },
        { value: 'Change Failure Rate' },
      ]);
    });
  });
});
