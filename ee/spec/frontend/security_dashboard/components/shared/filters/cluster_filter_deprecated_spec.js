import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import ClusterFilterDeprecated from 'ee/security_dashboard/components/shared/filters/cluster_filter_deprecated.vue';
import { CLUSTER_FILTER_ERROR } from 'ee/security_dashboard/components/shared/filters/constants';
import { clusterFilter } from 'ee/security_dashboard/helpers';
import clusterAgents from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { projectClusters } from '../../mock_data';

jest.mock('~/alert');

describe('Cluster Filter component (deprecated)', () => {
  let wrapper;
  const projectFullPath = 'test/path';
  const defaultQueryResolver = jest.fn().mockResolvedValue(projectClusters);

  const createMockApolloProvider = (queryResolver = defaultQueryResolver) => {
    Vue.use(VueApollo);
    return createMockApollo([[clusterAgents, queryResolver]]);
  };

  const createWrapper = (queryResolver = undefined) => {
    wrapper = shallowMount(ClusterFilterDeprecated, {
      apolloProvider: createMockApolloProvider(queryResolver),
      propsData: { filter: clusterFilter },
      provide: { projectFullPath },
    });
  };

  const findFilterItems = () => wrapper.findAllComponents(FilterItem);

  afterEach(() => {
    createAlert.mockClear();
  });

  it('retrieves the options', async () => {
    createWrapper();
    await waitForPromises();
    expect(defaultQueryResolver).toHaveBeenCalledTimes(1);
    expect(defaultQueryResolver.mock.calls[0][0]).toEqual({ projectPath: projectFullPath });
  });

  it('displays the filter options', async () => {
    createWrapper();
    await waitForPromises();
    const filterItems = findFilterItems();
    expect(filterItems.length).toBe(2);
    expect(filterItems.at(0).props()).toMatchObject({
      isChecked: true,
      text: 'All clusters',
    });
    expect(filterItems.at(1).props()).toMatchObject({
      isChecked: false,
      text: 'primary-agent',
    });
  });

  it('shows an alert on a failed graphql request', async () => {
    const errorSpy = jest.fn().mockRejectedValue();
    createWrapper(errorSpy);
    await waitForPromises();
    expect(createAlert).toHaveBeenCalledWith({ message: CLUSTER_FILTER_ERROR });
  });
});
