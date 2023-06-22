import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon, GlLink, GlAlert } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkspacesDropdownGroup from 'ee/remote_development/components/workspaces_dropdown_group/workspaces_dropdown_group.vue';
import WorkspaceDropdownItem from 'ee/remote_development/components/workspaces_dropdown_group/workspace_dropdown_item.vue';
import userWorkspacesListQuery from 'ee/remote_development/graphql/queries/user_workspaces_list.query.graphql';
import {
  WORKSPACES_DROPDOWN_GROUP_PAGE_SIZE,
  WORKSPACE_STATES,
} from 'ee/remote_development/constants';
import {
  USER_WORKSPACES_QUERY_EMPTY_RESULT,
  USER_WORKSPACES_QUERY_RESULT,
  PROJECT_ID,
} from '../../mock_data';

jest.mock('~/lib/logger');

Vue.use(VueApollo);

describe('remote_development/components/workspaces_dropdown_group/workspaces_dropdown_group.vue', () => {
  let wrapper;
  let mockApollo;
  let userWorkspacesListQueryHandler;

  const buildMockApollo = () => {
    userWorkspacesListQueryHandler = jest.fn().mockResolvedValueOnce(USER_WORKSPACES_QUERY_RESULT);

    mockApollo = createMockApollo([[userWorkspacesListQuery, userWorkspacesListQueryHandler]]);
  };
  const createWrapper = () => {
    wrapper = shallowMountExtended(WorkspacesDropdownGroup, {
      apolloProvider: mockApollo,
      provide: {
        projectId: PROJECT_ID,
      },
    });
  };
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkspacesLink = () => wrapper.findComponent(GlLink);
  const findAllWorkspaceItems = () => wrapper.findAllComponents(WorkspaceDropdownItem);
  const findNoWorkspacesMessage = () => wrapper.findByTestId('no-workspaces-message');
  const findLoadingWorkspacesErrorMessage = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    buildMockApollo();
  });

  describe('when loading data', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('executes GraphQL query', () => {
      expect(userWorkspacesListQueryHandler).toHaveBeenCalledWith({
        first: WORKSPACES_DROPDOWN_GROUP_PAGE_SIZE,
        after: null,
        before: null,
        includeActualStates: [
          WORKSPACE_STATES.creationRequested,
          WORKSPACE_STATES.starting,
          WORKSPACE_STATES.running,
          WORKSPACE_STATES.stopping,
          WORKSPACE_STATES.stopped,
          WORKSPACE_STATES.terminating,
          WORKSPACE_STATES.failed,
          WORKSPACE_STATES.error,
          WORKSPACE_STATES.unknown,
        ],
        projectIds: [PROJECT_ID],
      });
    });

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('displays loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not display no workspaces message', () => {
      expect(findNoWorkspacesMessage().exists()).toBe(false);
    });
  });

  describe('when graphql query fails', () => {
    const error = new Error('Error message');

    beforeEach(async () => {
      userWorkspacesListQueryHandler.mockReset();
      userWorkspacesListQueryHandler.mockRejectedValueOnce(error);

      createWrapper();

      await waitForPromises();
    });

    it('logs error', () => {
      expect(logError).toHaveBeenCalledWith(error);
    });

    it('displays loading workspaces error message', () => {
      expect(findLoadingWorkspacesErrorMessage().props()).toMatchObject({
        dismissible: false,
        showIcon: false,
        variant: 'danger',
      });
    });

    it('does not display workspaces', () => {
      expect(findAllWorkspaceItems()).toHaveLength(0);
    });

    it('does not display empty workspaces message', () => {
      expect(findNoWorkspacesMessage().exists()).toBe(false);
    });
  });

  describe('when user has workspaces', () => {
    beforeEach(async () => {
      userWorkspacesListQueryHandler.mockReset();
      userWorkspacesListQueryHandler.mockResolvedValueOnce(USER_WORKSPACES_QUERY_RESULT);

      createWrapper();
      await waitForPromises();
    });

    it('does not display loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays workspaces dropdown items', () => {
      const { nodes: workspaces } = USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces;

      workspaces.forEach((workspace, index) => {
        expect(findAllWorkspaceItems().at(index).props().workspace).toEqual(workspace);
      });
    });

    it('does not display no workspaces message', () => {
      expect(findNoWorkspacesMessage().exists()).toBe(false);
    });

    it('does not display error message', () => {
      expect(findLoadingWorkspacesErrorMessage().exists()).toBe(false);
    });
  });

  describe('when user does not have workspaces', () => {
    beforeEach(async () => {
      userWorkspacesListQueryHandler.mockReset();
      userWorkspacesListQueryHandler.mockResolvedValueOnce(USER_WORKSPACES_QUERY_EMPTY_RESULT);

      createWrapper();
      await waitForPromises();
    });

    it('does not display loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays no workspaces message', () => {
      expect(findNoWorkspacesMessage().exists()).toBe(true);
    });

    it('displays links pointing to the workspaces documentation', () => {
      expect(findWorkspacesLink().attributes().href).toBe('/help/user/workspace/index.md');
    });

    it('does not display error message', () => {
      expect(findLoadingWorkspacesErrorMessage().exists()).toBe(false);
    });
  });
});
