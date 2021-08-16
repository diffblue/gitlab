import { GlAlert, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import AgentEmptyState from 'ee/clusters_list/components/agent_empty_state.vue';
import AgentTable from 'ee/clusters_list/components/agent_table.vue';
import Agents from 'ee/clusters_list/components/agents.vue';
import getAgentsQuery from 'ee/clusters_list/graphql/queries/get_agents.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Agents', () => {
  let wrapper;

  const propsData = {
    defaultBranchName: 'default',
  };
  const provideData = {
    projectPath: 'path/to/project',
    kasAddress: 'kas.example.com',
  };

  const createWrapper = ({ agents = [], pageInfo = null, trees = [] }) => {
    const provide = provideData;
    const apolloQueryResponse = {
      data: {
        project: {
          clusterAgents: { nodes: agents, pageInfo },
          repository: { tree: { trees: { nodes: trees, pageInfo } } },
        },
      },
    };

    const apolloProvider = createMockApollo([
      [getAgentsQuery, jest.fn().mockResolvedValue(apolloQueryResponse, provide)],
    ]);

    wrapper = shallowMount(Agents, {
      localVue,
      apolloProvider,
      propsData,
      provide: provideData,
    });

    return wrapper.vm.$nextTick();
  };

  const findAgentTable = () => wrapper.find(AgentTable);
  const findEmptyState = () => wrapper.find(AgentEmptyState);
  const findPaginationButtons = () => wrapper.find(GlKeysetPagination);

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('when there is a list of agents', () => {
    const agents = [
      {
        id: '1',
        name: 'agent-1',
        webPath: '/agent-1',
      },
      {
        id: '2',
        name: 'agent-2',
        webPath: '/agent-2',
      },
    ];

    const trees = [
      {
        name: 'agent-2',
        path: '.gitlab/agents/agent-2',
        webPath: '/project/path/.gitlab/agents/agent-2',
      },
    ];

    beforeEach(() => {
      return createWrapper({ agents, trees });
    });

    it('should render agent table', () => {
      expect(findAgentTable().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should pass agent and folder info to table component', () => {
      expect(findAgentTable().props('agents')).toEqual([
        { id: '1', name: 'agent-1', webPath: '/agent-1', configFolder: undefined },
        {
          id: '2',
          name: 'agent-2',
          configFolder: {
            name: 'agent-2',
            path: '.gitlab/agents/agent-2',
            webPath: '/project/path/.gitlab/agents/agent-2',
          },
          webPath: '/agent-2',
        },
      ]);
    });

    it('should not render pagination buttons when there are no additional pages', () => {
      expect(findPaginationButtons().exists()).toBe(false);
    });

    describe('when the list has additional pages', () => {
      const pageInfo = {
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'prev',
        endCursor: 'next',
      };

      beforeEach(() => {
        return createWrapper({
          agents,
          pageInfo,
        });
      });

      it('should render pagination buttons', () => {
        expect(findPaginationButtons().exists()).toBe(true);
      });

      it('should pass pageInfo to the pagination component', () => {
        expect(findPaginationButtons().props()).toMatchObject(pageInfo);
      });
    });
  });

  describe('when the agent list is empty', () => {
    beforeEach(() => {
      return createWrapper({ agents: [] });
    });

    it('should render empty state', () => {
      expect(findAgentTable().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('when the agent configurations are present', () => {
    const trees = [
      {
        name: 'agent-1',
        path: '.gitlab/agents/agent-1',
        webPath: '/project/path/.gitlab/agents/agent-1',
      },
    ];

    beforeEach(() => {
      return createWrapper({ agents: [], trees });
    });

    it('should pass the correct hasConfigurations boolean value to empty state component', () => {
      expect(findEmptyState().props('hasConfigurations')).toEqual(true);
    });
  });

  describe('when agents query has errored', () => {
    beforeEach(() => {
      return createWrapper({ agents: null });
    });

    it('displays an alert message', () => {
      expect(wrapper.find(GlAlert).exists()).toBe(true);
    });
  });

  describe('when agents query is loading', () => {
    const mocks = {
      $apollo: {
        queries: {
          agents: {
            loading: true,
          },
        },
      },
    };

    beforeEach(() => {
      wrapper = shallowMount(Agents, { mocks, propsData, provide: provideData });

      return wrapper.vm.$nextTick();
    });

    it('displays a loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
