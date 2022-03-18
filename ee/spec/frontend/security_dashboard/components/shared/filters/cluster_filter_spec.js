import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import clusterAgentsFixtures from 'test_fixtures/graphql/security_dashboard/graphql/queries/cluster_agents.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import ClusterFilter from 'ee/security_dashboard/components/shared/filters/cluster_filter.vue';
import { clusterFilter } from 'ee/security_dashboard/helpers';
import clusterAgents from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';

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

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('retrieves the options', () => {
    expect(defaultQueryResolver).toHaveBeenCalledTimes(1);
    expect(defaultQueryResolver.mock.calls[0][0]).toEqual({ projectPath: 'test/path' });
  });
});
