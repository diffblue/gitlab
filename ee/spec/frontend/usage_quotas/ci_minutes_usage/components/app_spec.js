import { GlLoadingIcon, GlTab } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import CiMinutesUsageAppGroup from 'ee/usage_quotas/ci_minutes_usage/components/app.vue';
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import SharedRunnerUsageMonthChart from 'ee/ci_minutes_usage/components/shared_runner_usage_month_chart.vue';
import ciMinutesUsageGroup from 'ee/usage_quotas/ci_minutes_usage/graphql/queries/ci_minutes_namespace.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ciMinutesUsageMockData } from '../mock_data';

Vue.use(VueApollo);

describe('CI minutes usage app groups', () => {
  let wrapper;
  let queryHandlerSpy;

  function createMockApolloProvider() {
    const requestHandlers = [[ciMinutesUsageGroup, queryHandlerSpy]];

    return createMockApollo(requestHandlers);
  }

  function createComponent() {
    const apolloProvider = createMockApolloProvider();

    wrapper = shallowMountExtended(CiMinutesUsageAppGroup, {
      apolloProvider,
      provide: {
        namespaceId: 1,
      },
    });
  }

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMinutesUsageMonthChart = () => wrapper.findComponent(MinutesUsageMonthChart);
  const findSharedRunnerUsageMonthChart = () => wrapper.findComponent(SharedRunnerUsageMonthChart);
  const findMinutesUsageProjectChart = () => wrapper.findByTestId('minutes-by-project');
  const findSharedRunnerUsageProjectChart = () => wrapper.findByTestId('shared-runner-by-project');
  const findAllTabs = () => wrapper.findAllComponents(GlTab);

  beforeEach(() => {
    queryHandlerSpy = jest.fn().mockResolvedValue(ciMinutesUsageMockData);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('calls query with namespaceId variable', () => {
    createComponent();

    expect(queryHandlerSpy).toHaveBeenCalledWith({ namespaceId: 'gid://gitlab/Group/1' });
  });

  it('should display loading icon while query is fetching', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('after query finishes', () => {
    it('should display the correct number of tabs', async () => {
      createComponent();
      await waitForPromises();
      await nextTick();

      expect(findAllTabs()).toHaveLength(4);
    });

    it('should render minutes usage month chart', async () => {
      createComponent();
      await waitForPromises();
      await nextTick();

      expect(findMinutesUsageMonthChart().props()).toEqual({
        ciMinutesUsage: ciMinutesUsageMockData.data.ciMinutesUsage.nodes,
      });
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('should render shared runner usage month chart', async () => {
      createComponent();
      await waitForPromises();
      await nextTick();

      expect(findSharedRunnerUsageMonthChart().props()).toEqual({
        ciMinutesUsage: ciMinutesUsageMockData.data.ciMinutesUsage.nodes,
      });
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('should render minutes usage project chart', async () => {
      createComponent();
      await waitForPromises();
      await nextTick();

      expect(findMinutesUsageProjectChart().props()).toEqual({
        minutesUsageData: ciMinutesUsageMockData.data.ciMinutesUsage.nodes,
        displaySharedRunnerData: false,
      });
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('should render shared runner usage project chart', async () => {
      createComponent();
      await waitForPromises();
      await nextTick();

      expect(findSharedRunnerUsageProjectChart().props()).toEqual({
        minutesUsageData: ciMinutesUsageMockData.data.ciMinutesUsage.nodes,
        displaySharedRunnerData: true,
      });
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });
});
