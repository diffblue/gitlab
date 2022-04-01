import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import clusterAgentsFixtures from 'test_fixtures/graphql/security_dashboard/graphql/queries/cluster_agents.query.graphql.json';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import createMockApollo from 'helpers/mock_apollo_helper';
import ClusterFilter from 'ee/security_dashboard/components/shared/filters/cluster_filter.vue';
import { CLUSTER_FILTER_ERROR } from 'ee/security_dashboard/components/shared/filters/constants';
import { clusterFilter } from 'ee/security_dashboard/helpers';
import clusterAgents from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';

jest.mock('~/flash');

describe('Cluster Filter component', () => {
  let wrapper;
  const defaultQueryResolver = jest.fn().mockResolvedValue(clusterAgentsFixtures);

  const createMockApolloProvider = (queryResolver = defaultQueryResolver) => {
    Vue.use(VueApollo);
    return createMockApollo([[clusterAgents, queryResolver]]);
  };

  const createWrapper = (queryResolver = undefined) => {
    wrapper = shallowMount(ClusterFilter, {
      apolloProvider: createMockApolloProvider(queryResolver),
      propsData: { filter: clusterFilter },
      provide: { projectFullPath: 'test/path' },
    });
  };

  afterEach(() => {
    createFlash.mockClear();
    wrapper.destroy();
  });

  it('retrieves the options', async () => {
    createWrapper();
    await waitForPromises();
    expect(defaultQueryResolver).toHaveBeenCalledTimes(1);
    expect(defaultQueryResolver.mock.calls[0][0]).toEqual({ projectPath: 'test/path' });
  });

  it('shows an alert on a failed graphql request', async () => {
    const errorSpy = jest.fn().mockRejectedValue();
    createWrapper(errorSpy);
    await waitForPromises();
    expect(createFlash).toHaveBeenCalledWith({ message: CLUSTER_FILTER_ERROR });
  });
});
