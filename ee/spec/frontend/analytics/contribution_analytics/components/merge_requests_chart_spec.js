import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MergeRequestsChart from 'ee/analytics/contribution_analytics/components/merge_requests_chart.vue';
import { MOCK_ANALYTICS } from '../mock_data';

describe('Contribution Analytics Merge Requests Chart', () => {
  let wrapper;

  const findDescription = () => wrapper.findComponent(GlSprintf).attributes('message');

  const createWrapper = ({ provide = {} } = {}) => {
    wrapper = shallowMount(MergeRequestsChart, {
      provide: {
        ...MOCK_ANALYTICS,
        ...provide,
      },
    });
  };

  it('renders the empty description when there is no table data', () => {
    createWrapper({
      provide: {
        totalMergeRequestsClosedCount: 0,
        totalMergeRequestsCreatedCount: 0,
        totalMergeRequestsMergedCount: 0,
      },
    });

    expect(findDescription()).toBe(wrapper.vm.$options.i18n.emptyDescription);
  });

  it('renders the description based on the table data', () => {
    createWrapper();
    expect(findDescription()).toEqual(expect.stringMatching(wrapper.vm.$options.i18n.description));
  });
});
