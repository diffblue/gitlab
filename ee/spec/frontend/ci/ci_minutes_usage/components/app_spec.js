import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import CiMinutesUsageApp from 'ee/ci/ci_minutes_usage/components/app.vue';
import MinutesUsageMonthChart from 'ee/ci/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from 'ee/ci/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import SharedRunnerUsageMonthChart from 'ee/ci/ci_minutes_usage/components/shared_runner_usage_month_chart.vue';
import ciMinutesUsage from 'ee/ci/ci_minutes_usage/graphql/queries/ci_minutes.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
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
  const findAllMinutesUsageProjectChart = () => wrapper.findAllComponents(MinutesUsageProjectChart);
  const findSharedRunnerUsageMonthChart = () => wrapper.findComponent(SharedRunnerUsageMonthChart);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);

  beforeEach(async () => {
    const fakeApollo = createMockApolloProvider();
    wrapper = createComponent({
      fakeApollo,
    });

    await waitForPromises();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should contain three charts', () => {
    expect(findMinutesUsageMonthChart().exists()).toBe(true);
    expect(findAllMinutesUsageProjectChart()).toHaveLength(2);
    expect(findSharedRunnerUsageMonthChart().exists()).toBe(true);
  });

  it('should display four tabs', () => {
    expect(findAllTabs()).toHaveLength(4);
  });
});
