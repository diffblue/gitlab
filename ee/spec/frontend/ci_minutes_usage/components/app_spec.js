import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import CiMinutesUsageApp from 'ee/ci_minutes_usage/components/app.vue';
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from 'ee/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import ciMinutesUsage from 'ee/ci_minutes_usage/graphql/queries/ci_minutes.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { ciMinutesUsageMockData } from '../mock_data';

Vue.use(VueApollo);

describe('CI minutes usage app', () => {
  let wrapper;

  function createMockApolloProvider() {
    const requestHandlers = [[ciMinutesUsage, jest.fn().mockResolvedValue(ciMinutesUsageMockData)]];

    return createMockApollo(requestHandlers);
  }

  function createComponent(options = {}) {
    const { fakeApollo } = options;

    return shallowMount(CiMinutesUsageApp, {
      apolloProvider: fakeApollo,
    });
  }

  const findMinutesUsageMonthChart = () => wrapper.findComponent(MinutesUsageMonthChart);
  const findMinutesUsageProjectChart = () => wrapper.findComponent(MinutesUsageProjectChart);

  beforeEach(() => {
    const fakeApollo = createMockApolloProvider();
    wrapper = createComponent({ fakeApollo });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should contain two charts', () => {
    expect(findMinutesUsageMonthChart().exists()).toBe(true);
    expect(findMinutesUsageProjectChart().exists()).toBe(true);
  });
});
