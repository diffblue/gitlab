import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ColumnChart from 'ee/analytics/contribution_analytics/components/column_chart.vue';
import MergeRequestsChart from 'ee/analytics/contribution_analytics/components/merge_requests_chart.vue';
import { MOCK_MERGE_REQUESTS } from '../mock_data';

describe('Contribution Analytics Merge Requests Chart', () => {
  let wrapper;

  const findDescription = () => wrapper.findByTestId('description').text();
  const findChart = () => wrapper.findComponent(ColumnChart);

  const createWrapper = (mergeRequests) => {
    wrapper = shallowMountExtended(MergeRequestsChart, {
      propsData: {
        mergeRequests,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  it('renders the empty description when there is no table data', () => {
    createWrapper([]);
    expect(findDescription()).toBe(wrapper.vm.$options.i18n.emptyDescription);
  });

  it('renders the description based on the table data', () => {
    createWrapper(MOCK_MERGE_REQUESTS);
    expect(findDescription()).toBe('31 created, 32 merged, 36 closed.');
  });

  it('sorts the chart by created merge requests in descending order', () => {
    createWrapper(MOCK_MERGE_REQUESTS);
    expect(findChart().props('chartData')).toEqual([
      ['nami', 17],
      ['zoro', 9],
      ['luffy', 5],
    ]);
  });
});
