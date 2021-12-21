import { GlDropdownItem, GlModal, GlFormInput } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import getAgentsQuery from '~/clusters_list/graphql/queries/get_agents.query.graphql';
import deleteAgentMutation from '~/clusters_list/graphql/mutations/delete_agent.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import AgentActions from '~/clusters_list/components/agent_actions.vue';
import { MAX_LIST_COUNT } from '~/clusters_list/constants';
import { getAgentResponse, mockDeleteResponse, mockErrorDeleteResponse } from '../mocks/apollo';

Vue.use(VueApollo);

const projectPath = 'path/to/project';
const defaultBranchName = 'default';
const maxAgents = MAX_LIST_COUNT;
const agent = {
  id: 'agent-id',
  name: 'agent-name',
  webPath: 'agent-webPath',
};

describe('AgentActions', () => {
  let wrapper;
  let toast;
  let apolloProvider;
  let deleteResponse;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteBtn = () => wrapper.findComponent(GlDropdownItem);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findPrimaryAction = () => findModal().props('actionPrimary');
  const findPrimaryActionAttributes = (attr) => findPrimaryAction().attributes[0][attr];

  const createMockApolloProvider = ({ mutationResponse }) => {
    deleteResponse = jest.fn().mockResolvedValue(mutationResponse);

    return createMockApollo([[deleteAgentMutation, deleteResponse]]);
  };

  const writeQuery = () => {
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: getAgentsQuery,
      variables: {
        projectPath,
        defaultBranchName,
        first: maxAgents,
        last: null,
      },
      data: getAgentResponse.data,
    });
  };

  const createWrapper = ({ mutationResponse = mockDeleteResponse } = {}) => {
    apolloProvider = createMockApolloProvider({ mutationResponse });
    const provide = {
      projectPath,
    };
    const propsData = {
      defaultBranchName,
      maxAgents,
      agent,
    };

    toast = jest.fn();

    wrapper = shallowMountExtended(AgentActions, {
      apolloProvider,
      provide,
      propsData,
      mocks: { $toast: { show: toast } },
      stubs: { GlModal },
    });
    wrapper.vm.$refs.modal.hide = jest.fn();

    writeQuery();
    return wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    return createWrapper({});
  });

  afterEach(() => {
    wrapper.destroy();
    apolloProvider = null;
    deleteResponse = null;
    toast = null;
  });

  describe('delete agent action', () => {
    it('displays a delete button', () => {
      expect(findDeleteBtn().text()).toBe('Delete agent');
    });

    describe('when clicking the delete button', () => {
      beforeEach(() => {
        findDeleteBtn().vm.$emit('click');
      });

      it('displays a delete confirmation modal', () => {
        expect(findModal().isVisible()).toBe(true);
      });
    });

    describe('when the input with agent name is missing', () => {
      beforeEach(() => {
        findDeleteBtn().vm.$emit('click');
      });

      it('disables the modal primary button', () => {
        expect(findPrimaryActionAttributes('disabled')).toBe(true);
      });
    });

    describe('when submitting the delete modal and the input with agent name is correct ', () => {
      beforeEach(() => {
        findDeleteBtn().vm.$emit('click');
        findInput().vm.$emit('input', agent.name);
        findModal().vm.$emit('primary');

        return wrapper.vm.$nextTick();
      });

      it('calls the delete mutation', () => {
        expect(deleteResponse).toHaveBeenCalledWith({ input: { id: agent.id } });
      });

      it('calls the toast action', () => {
        expect(toast).toHaveBeenCalledWith(`${agent.name} successfully deleted`);
      });
    });
  });

  describe('when getting an error deleting agent', () => {
    beforeEach(async () => {
      await createWrapper({ mutationResponse: mockErrorDeleteResponse });

      findDeleteBtn().vm.$emit('click');
      findModal().vm.$emit('primary');
    });

    it('displays the error message', () => {
      expect(toast).toHaveBeenCalledWith('could not delete agent');
    });
  });
});
