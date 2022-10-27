import { shallowMount } from '@vue/test-utils';
import Component from 'ee/analytics/dashboards/components/app.vue';
import DoraComparisonTable from 'ee/analytics/dashboards/components/dora_comparison_table.vue';
import * as utils from '~/analytics/shared/utils';
import { mockCurrentApiResponse, mockPreviousApiResponse } from '../mock_data';

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

    it('will request the summary and time summary metrics for both time periods', () => {
      expect(utils.fetchMetricsData).toHaveBeenCalledTimes(2);

      expectDataRequests({ created_after: '2020-06-07', created_before: '2020-07-06' });
      expectDataRequests({ created_after: '2020-05-09', created_before: '2020-06-07' });
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

  describe('no previous data', () => {
    beforeEach(async () => {
      utils.fetchMetricsData.mockReturnValueOnce(mockCurrentApiResponse).mockReturnValueOnce([]);

      wrapper = await createComponent();
    });

    it('calculates no % change for each DORA metric', async () => {
      const momChange = getTableData().map(({ change }) => change);

      expect(momChange).toEqual(['-', '-', '-', '-']);
    });
  });

  describe('with current and previous data to compare', () => {
    beforeEach(async () => {
      utils.fetchMetricsData
        .mockReturnValueOnce(mockCurrentApiResponse)
        .mockReturnValueOnce(mockPreviousApiResponse);

      wrapper = await createComponent();
    });

    it('renders each DORA metric', () => {
      const metricNames = getTableData().map(({ metric }) => metric);

      expect(metricNames).toEqual([
        'Deployment Frequency',
        'Lead Time for Changes',
        'Time to Restore Service',
        'Change Failure Rate',
      ]);
    });

    it('calculates % change for each DORA metric', () => {
      const momChange = getTableData().map(({ change }) => change);

      expect(momChange).toEqual(['1070.59%', '-92%', '-98.21%', '64.23%']);
    });
  });
});
