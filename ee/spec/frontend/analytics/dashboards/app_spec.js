import { shallowMount, mount } from '@vue/test-utils';
import { GlTableLite } from '@gitlab/ui';
import * as utils from '~/analytics/shared/utils';
import Component from 'ee/analytics/dashboards/app.vue';
import DoraComparisonTable from 'ee/analytics/dashboards/dora_comparison_table.vue';
import {
  mockCurrentApiResponse,
  mockPreviousApiResponse,
  mockComparativeTableData,
} from './mock_data';

const mockProps = { groupName: 'Exec group', groupFullPath: 'exec-group' };

jest.mock('~/analytics/shared/utils');

describe('Executive dashboard app', () => {
  let wrapper;

  function createComponent({ props = {}, mountFn = shallowMount } = {}) {
    return mountFn(Component, {
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

  describe('data', () => {
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

  describe('with data', () => {
    beforeEach(async () => {
      utils.fetchMetricsData
        .mockImplementationOnce(() => Promise.resolve(mockCurrentApiResponse))
        .mockImplementationOnce(() => Promise.resolve(mockPreviousApiResponse));

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
