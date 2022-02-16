import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import CiMinutesUsageAppGroup from 'ee/usage_quotas/ci_minutes_usage/components/app.vue';
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from 'ee/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import ciMinutesUsageGroup from 'ee/usage_quotas/ci_minutes_usage/graphql/queries/ci_minutes_namespace.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
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

    wrapper = shallowMount(CiMinutesUsageAppGroup, {
      apolloProvider,
      provide: {
        namespaceId: 1,
      },
    });
  }

  const findMinutesUsageMonthChart = () => wrapper.findComponent(MinutesUsageMonthChart);
  const findMinutesUsageProjectChart = () => wrapper.findComponent(MinutesUsageProjectChart);

  beforeEach(() => {
    queryHandlerSpy = jest.fn().mockResolvedValue(ciMinutesUsageMockData);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('calls query with namespaceId variable', () => {
    expect(queryHandlerSpy).toHaveBeenCalledWith({ namespaceId: 'gid://gitlab/Group/1' });
  });

  describe('after query finishes', () => {
    beforeEach(async () => {
      await waitForPromises();
      await nextTick();
    });

    it('should render minutes usage month chart', () => {
      expect(findMinutesUsageMonthChart().props()).toEqual({
        minutesUsageData: [
          ['Jun 2021', 5],
          ['Jul 2021', 0],
        ],
      });
    });

    it('should render minutes usage project chart', () => {
      expect(findMinutesUsageProjectChart().props()).toEqual({
        minutesUsageData: ciMinutesUsageMockData.data.ciMinutesUsage.nodes,
      });
    });
  });
});
