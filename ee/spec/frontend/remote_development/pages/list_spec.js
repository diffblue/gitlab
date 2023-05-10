import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlAlert, GlBadge, GlButton, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkspaceList from 'ee/remote_development/pages/list.vue';
import WorkspaceEmptyState from 'ee/remote_development/components/list/empty_state.vue';
import WorkspacesTable from 'ee/remote_development/components/list/workspaces_table.vue';
import WorkspacesListPagination from 'ee/remote_development/components/list/workspaces_list_pagination.vue';
import userWorkspacesListQuery from 'ee/remote_development/graphql/queries/user_workspaces_list.query.graphql';
import userWorkspacesProjectsNamesQuery from 'ee/remote_development/graphql/queries/user_workspaces_projects_names.query.graphql';
import { ROUTES } from 'ee/remote_development/constants';
import { populateWorkspacesWithProjectNames } from 'ee/remote_development/services/utils';
import {
  USER_WORKSPACES_QUERY_RESULT,
  USER_WORKSPACES_QUERY_EMPTY_RESULT,
  USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT,
} from '../mock_data';

jest.mock('~/lib/logger');

Vue.use(VueApollo);

const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';

describe('remote_development/pages/list.vue', () => {
  let wrapper;
  let mockApollo;
  let userWorkspacesListQueryHandler;
  let userWorkspacesProjectNamesQueryHandler;

  const buildMockApollo = () => {
    userWorkspacesListQueryHandler = jest.fn().mockResolvedValueOnce(USER_WORKSPACES_QUERY_RESULT);
    userWorkspacesProjectNamesQueryHandler = jest
      .fn()
      .mockResolvedValueOnce(USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT);

    mockApollo = createMockApollo([
      [userWorkspacesListQuery, userWorkspacesListQueryHandler],
      [userWorkspacesProjectsNamesQuery, userWorkspacesProjectNamesQueryHandler],
    ]);
  };
  const createWrapper = () => {
    wrapper = mount(WorkspaceList, {
      apolloProvider: mockApollo,
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
    });
  };
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findTable = () => wrapper.findComponent(WorkspacesTable);
  const findPagination = () => wrapper.findComponent(WorkspacesListPagination);
  const findNewWorkspaceButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    buildMockApollo();
  });

  describe('when no workspaces are available', () => {
    beforeEach(async () => {
      userWorkspacesListQueryHandler.mockReset();
      userWorkspacesListQueryHandler.mockResolvedValueOnce(USER_WORKSPACES_QUERY_EMPTY_RESULT);

      createWrapper();
      await waitForPromises();
    });

    it('renders empty state when no workspaces are available', () => {
      expect(wrapper.findComponent(WorkspaceEmptyState).exists()).toBe(true);
    });

    it('does not render the workspaces table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('does not render the workspaces pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  it('shows loading state when workspaces are being fetched', () => {
    createWrapper();
    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('default (with nodes)', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('renders table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders pagination', () => {
      expect(findPagination().exists()).toBe(true);
    });

    it('provides workspaces data to the workspaces table', () => {
      expect(findTable(wrapper).props('workspaces')).toEqual(
        populateWorkspacesWithProjectNames(
          USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes,
          USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT.data.projects.nodes,
        ),
      );
    });

    it('does not call log error', () => {
      expect(logError).not.toHaveBeenCalled();
    });

    it('does not show alert', () => {
      expect(findAlert(wrapper).exists()).toBe(false);
    });

    describe('when pagination component emits input event', () => {
      it('refetches workspaces starting at the specified cursor', async () => {
        const pageVariables = { after: 'end', first: 10 };

        createWrapper();

        await waitForPromises();

        expect(userWorkspacesListQueryHandler).toHaveBeenCalledTimes(1);

        findPagination().vm.$emit('input', pageVariables);

        await waitForPromises();

        expect(userWorkspacesListQueryHandler).toHaveBeenCalledTimes(2);
        expect(userWorkspacesListQueryHandler).toHaveBeenLastCalledWith(pageVariables);
      });
    });
  });

  describe('when workspace table emits updateFailed event', () => {
    it('displays the error attached to the event', async () => {
      const error = 'Failed to stop workspace';

      createWrapper();
      await waitForPromises();

      findTable().vm.$emit('updateFailed', { error });

      await nextTick();

      expect(findAlert().text()).toBe(error);
    });
  });

  describe.each`
    query                            | queryHandlerFactory
    ${'userWorkspaces'}              | ${() => userWorkspacesListQueryHandler}
    ${'userWorkspacesProjectsNames'} | ${() => userWorkspacesProjectNamesQueryHandler}
  `('when $query query fails', ({ queryHandlerFactory }) => {
    const ERROR = new Error('Something bad!');

    beforeEach(async () => {
      const queryHandler = queryHandlerFactory();

      queryHandler.mockReset();
      queryHandler.mockRejectedValueOnce(ERROR);

      createWrapper();
      await waitForPromises();
    });

    it('does not render table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('logs error', () => {
      expect(logError).toHaveBeenCalledWith(ERROR);
    });

    it('shows alert', () => {
      expect(findAlert().text()).toBe(
        'Unable to load current Workspaces. Please try again or contact an administrator.',
      );
    });

    it('hides error when alert is dismissed', async () => {
      findAlert().vm.$emit('dismiss');

      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('fixed elements', () => {
    beforeEach(async () => {
      createWrapper();

      await waitForPromises();
    });
    it('displays a link button that navigates to the create workspace page', () => {
      expect(findNewWorkspaceButton().attributes().to).toBe(ROUTES.create);
      expect(findNewWorkspaceButton().text()).toMatch(/New workspace/);
    });

    it('displays a beta badge', () => {
      expect(wrapper.findComponent(GlBadge).props().variant).toBe('info');
    });

    it('displays a link that navigates to the workspaces help page', () => {
      expect(findHelpLink().attributes().href).toContain('user/workspace/index.md');
    });
  });
});
