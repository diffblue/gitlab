import { shallowMount, mount } from '@vue/test-utils';
import { GlTableLite } from '@gitlab/ui';
import * as utils from '~/analytics/shared/utils';
import Component from 'ee/analytics/dashboards/app.vue';
import { mockCurrentApiResponse, mockPreviousApiResponse } from './mock_data';

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

  const findComparisonTable = () => wrapper.findComponent(GlTableLite);

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

    it.skip('renders each DORA metric', () => {
      const tableItems = findComparisonTable().attributes();
      tableItems.forEach((item) => {
        expect(item).toBe({});
      });
    });
  });
});
