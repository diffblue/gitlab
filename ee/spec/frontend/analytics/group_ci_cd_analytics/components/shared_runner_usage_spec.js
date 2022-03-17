import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import SharedRunnerUsage from 'ee/analytics/group_ci_cd_analytics/components/shared_runner_usage.vue';
import getCiMinutesUsageByNamespace from 'ee/analytics/group_ci_cd_analytics/graphql/ci_minutes.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { ciMinutesUsageNamespace } from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Shared runner usage tab', () => {
  let wrapper;

  const createComponent = ({ isLoading = false, options } = {}) => {
    const mockApolloLoading = {
      mocks: {
        $apollo: {
          queries: {
            ciMinutesUsage: {
              loading: isLoading,
            },
          },
        },
      },
    };
    const mock = options?.apolloProvider ? {} : mockApolloLoading;

    wrapper = shallowMount(SharedRunnerUsage, {
      provide: {
        groupId: '1',
      },
      ...mock,
      ...options,
    });
  };

  const createComponentWithApollo = () => {
    const ciMinutesMock = jest.fn().mockResolvedValue(ciMinutesUsageNamespace);

    const handlers = [[getCiMinutesUsageByNamespace, ciMinutesMock]];
    const apolloProvider = createMockApollo(handlers);

    createComponent({
      options: {
        localVue,
        apolloProvider,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);

  describe('when the data has successfully loaded', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      await waitForPromises();
    });

    it('should display the chart', () => {
      expect(findAreaChart().exists()).toBe(true);
    });

    it('should contain a responsive attribute for the area chart', () => {
      expect(findAreaChart().attributes('responsive')).toBeDefined();
    });
  });

  describe('when the component is loading data', () => {
    beforeEach(() => {
      createComponent({ isLoading: true });
    });

    it('should not display the chart', () => {
      expect(findAreaChart().exists()).toBe(false);
    });
  });
});
