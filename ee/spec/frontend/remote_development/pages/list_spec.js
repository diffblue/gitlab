import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlAlert, GlButton, GlLink, GlTableLite, GlSkeletonLoader } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORKSPACE } from '~/graphql_shared/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkspaceList, { i18n } from 'ee/remote_development/pages/list.vue';
import WorkspaceEmptyState from 'ee/remote_development/components/list/empty_state.vue';
import WorkspaceStateIndicator from 'ee/remote_development/components/list/workspace_state_indicator.vue';
import TerminateWorkspaceButton from 'ee/remote_development/components/list/terminate_workspace_button.vue';
import StopWorkspaceButton from 'ee/remote_development/components/list/stop_workspace_button.vue';
import StartWorkspaceButton from 'ee/remote_development/components/list/start_workspace_button.vue';
import RestartWorkspaceButton from 'ee/remote_development/components/list/restart_workspace_button.vue';
import userWorkspacesListQuery from 'ee/remote_development/graphql/queries/user_workspaces_list.query.graphql';
import { useFakeDate } from 'helpers/fake_date';

import {
  WORKSPACE_STATES,
  WORKSPACE_DESIRED_STATES,
  ROUTES,
} from 'ee/remote_development/constants';
import {
  CURRENT_USERNAME,
  USER_WORKSPACES_QUERY_RESULT,
  USER_WORKSPACES_QUERY_EMPTY_RESULT,
} from '../mock_data';

jest.mock('~/lib/logger');

Vue.use(VueApollo);

const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';

const findAlert = (wrapper) => wrapper.findComponent(GlAlert);
const findTable = (wrapper) => wrapper.findComponent(GlTableLite);
const findTableRows = (wrapper) => findTable(wrapper).findAll('tbody tr');
const findTableRowsAsData = (wrapper) =>
  findTableRows(wrapper).wrappers.map((x) => {
    const tds = x.findAll('td');
    const rowData = {
      nameText: tds.at(0).text(),
      workspaceState: tds.at(0).findComponent(WorkspaceStateIndicator).props('workspaceState'),
    };

    if (tds.at(1).findComponent(GlLink).exists()) {
      rowData.previewText = tds.at(1).text();
      rowData.previewHref = tds.at(1).findComponent(GlLink).attributes('href');
    }

    return rowData;
  });
const findNewWorkspaceButton = (wrapper) => wrapper.findComponent(GlButton);

describe('remote_development/pages/list.vue', () => {
  let wrapper;
  let userWorkspacesListQueryHandler;
  let workspaceUpdateMutationHandler;

  const createWrapper = (mockData = USER_WORKSPACES_QUERY_RESULT) => {
    userWorkspacesListQueryHandler = jest.fn().mockResolvedValueOnce(mockData);
    workspaceUpdateMutationHandler = jest.fn();

    const mockApollo = createMockApollo(
      [[userWorkspacesListQuery, userWorkspacesListQueryHandler]],
      {
        Mutation: {
          workspaceUpdate: workspaceUpdateMutationHandler,
        },
      },
    );

    wrapper = mount(WorkspaceList, {
      apolloProvider: mockApollo,
      provide: {
        emptyStateSvgPath: SVG_PATH,
        currentUsername: CURRENT_USERNAME,
      },
    });
  };
  const setupMockTerminatedWorkspace = (extraData = {}) => {
    const customData = cloneDeep(USER_WORKSPACES_QUERY_RESULT);
    const workspace = cloneDeep(customData.data.currentUser.workspaces.nodes[0]);

    customData.data.currentUser.workspaces.nodes.unshift({
      ...workspace,
      actualState: WORKSPACE_STATES.terminated,
      ...extraData,
    });

    return customData;
  };
  useFakeDate(2023, 4, 1);

  it('shows empty state when no workspaces are available', async () => {
    createWrapper(USER_WORKSPACES_QUERY_EMPTY_RESULT);
    await waitForPromises();
    expect(wrapper.findComponent(WorkspaceEmptyState).exists()).toBe(true);
  });

  it('shows loading state when workspaces are being fetched', () => {
    createWrapper();
    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('default (with nodes)', () => {
    beforeEach(async () => {
      createWrapper(USER_WORKSPACES_QUERY_RESULT);
      await waitForPromises();
    });

    it('shows table when workspaces are available', () => {
      expect(findTable(wrapper).exists()).toBe(true);
    });

    it('displays user workspaces correctly', () => {
      expect(findTableRowsAsData(wrapper)).toEqual(
        USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes.map((x) => {
          const workspaceData = {
            nameText: `${x.projectId}   ${x.name}`,
            workspaceState: x.actualState,
          };

          if (x.actualState === WORKSPACE_STATES.running) {
            workspaceData.previewText = x.url;
            workspaceData.previewHref = x.url;
          }

          return workspaceData;
        }),
      );
    });

    it('does not call log error', () => {
      expect(logError).not.toHaveBeenCalled();
    });

    it('does not show alert', () => {
      expect(findAlert(wrapper).exists()).toBe(false);
    });

    describe('when the query returns terminated workspaces', () => {
      beforeEach(async () => {
        createWrapper(setupMockTerminatedWorkspace());

        await waitForPromises();
      });

      it('sorts the list to display terminated workspaces at the end of the list', () => {
        expect(findTableRowsAsData(wrapper).pop().workspaceState).toBe(WORKSPACE_STATES.terminated);
      });
    });

    describe('when the query returns terminated workspaces older than five days', () => {
      const oldTerminatedWorkspaceName = 'terminated-workspace-older-than-five-days';
      const oldRunningWorkspaceName = 'running-workspace-older-than-five-days';
      const createdAt = new Date(2023, 3, 1);

      beforeEach(async () => {
        const customData = setupMockTerminatedWorkspace({
          name: oldTerminatedWorkspaceName,
          createdAt,
        });
        const oldRunningWorkspace = {
          ...customData.data.currentUser.workspaces.nodes[0],
          actualState: WORKSPACE_STATES.running,
          name: oldRunningWorkspaceName,
          createdAt,
        };
        customData.data.currentUser.workspaces.nodes.unshift(oldRunningWorkspace);

        createWrapper(customData);

        await waitForPromises();
      });

      it('excludes terminated workspaces older than five days from the workspaces list', () => {
        expect(findTableRowsAsData(wrapper)).not.toContainEqual(
          expect.objectContaining({
            nameText: expect.stringContaining(oldTerminatedWorkspaceName),
          }),
        );
      });

      it('displays non-terminated older than five days from the workspaces list', () => {
        expect(findTableRowsAsData(wrapper)).toContainEqual(
          expect.objectContaining({
            nameText: expect.stringContaining(oldRunningWorkspaceName),
          }),
        );
      });
    });
  });

  describe('when the query returns only terminated workspaces older than five days', () => {
    beforeEach(async () => {
      const customData = setupMockTerminatedWorkspace({
        name: 'terminated-workspace-older-than-five-days',
        createdAt: new Date(2023, 3, 1),
      });
      customData.data.currentUser.workspaces.nodes = [
        customData.data.currentUser.workspaces.nodes.shift(),
      ];
      createWrapper(customData);

      await waitForPromises();
    });

    it('displays empty state illustration', () => {
      expect(wrapper.findComponent(WorkspaceEmptyState).exists()).toBe(true);
    });

    it('hides workspaces table', () => {
      expect(findTable(wrapper).exists()).toBe(false);
    });
  });

  describe.each`
    buttonName     | buttonComponent             | desiredState
    ${'terminate'} | ${TerminateWorkspaceButton} | ${WORKSPACE_DESIRED_STATES.terminated}
    ${'stop'}      | ${StopWorkspaceButton}      | ${WORKSPACE_DESIRED_STATES.stopped}
    ${'start'}     | ${StartWorkspaceButton}     | ${WORKSPACE_DESIRED_STATES.running}
    ${'restart'}   | ${RestartWorkspaceButton}   | ${WORKSPACE_DESIRED_STATES.restartRequested}
  `('"$buttonName" button', ({ buttonComponent, desiredState }) => {
    beforeEach(async () => {
      createWrapper(USER_WORKSPACES_QUERY_RESULT);

      await waitForPromises();
    });

    it('displays the button for every workspace', () => {
      USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes.forEach((workspace, index) => {
        const button = wrapper.findAllComponents(buttonComponent).at(index);

        expect(button.props()).toEqual({
          actualState: workspace.actualState,
          desiredState: workspace.desiredState,
        });
      });
    });

    describe('when clicking', () => {
      let workspace;
      let button;

      beforeEach(() => {
        // eslint-disable-next-line prefer-destructuring
        workspace = USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes[0];
        button = wrapper.findAllComponents(buttonComponent).at(0);
      });

      it(`sets workspace desiredState as "${desiredState}" using the workspaceUpdate mutation`, async () => {
        button.vm.$emit('click');

        await waitForPromises();

        expect(workspaceUpdateMutationHandler).toHaveBeenCalledWith(
          expect.any(Object),
          {
            input: {
              desiredState,
              id: convertToGraphQLId(TYPE_WORKSPACE, workspace.id),
            },
          },
          expect.any(Object),
          expect.any(Object),
        );
      });

      describe('when the workspaceUpdate mutation returns an error message response', () => {
        const error = 'error message';

        beforeEach(() => {
          workspaceUpdateMutationHandler.mockReset();
          workspaceUpdateMutationHandler.mockResolvedValueOnce({
            workspace: null,
            errors: [error],
          });
        });

        it('shows the error message in a danger alert', async () => {
          button.vm.$emit('click');

          await waitForPromises();

          expect(findAlert(wrapper).text()).toContain(error);
        });
      });

      describe('when the workspaceUpdate mutation fails', () => {
        const error = new Error();

        beforeEach(async () => {
          workspaceUpdateMutationHandler.mockReset();
          workspaceUpdateMutationHandler.mockRejectedValueOnce(error);

          button.vm.$emit('click');

          await waitForPromises();
        });

        it('shows an alert indicating that the update operation failed', () => {
          expect(findAlert(wrapper).text()).toContain(i18n.updateWorkspaceFailedMessage);
        });

        it('logs the error', () => {
          expect(logError).toHaveBeenCalledWith(error);
        });
      });
    });
  });

  describe('when query fails', () => {
    const ERROR = new Error('Something bad!');

    beforeEach(async () => {
      createWrapper(Promise.reject(ERROR));
      await waitForPromises();
    });

    it('does not render table', () => {
      expect(findTable(wrapper).exists()).toBe(false);
    });

    it('logs error', () => {
      expect(logError).toHaveBeenCalledWith(ERROR);
    });

    it('shows alert', () => {
      expect(findAlert(wrapper).text()).toBe(
        'Unable to load current Workspaces. Please try again or contact an administrator.',
      );
    });

    it('hides error when alert is dismissed', async () => {
      findAlert(wrapper).vm.$emit('dismiss');

      await nextTick();

      expect(findAlert(wrapper).exists()).toBe(false);
    });
  });

  it('displays a link button that navigates to the create workspace page', async () => {
    createWrapper();

    await waitForPromises();

    expect(findNewWorkspaceButton(wrapper).attributes().to).toBe(ROUTES.create);
    expect(findNewWorkspaceButton(wrapper).text()).toMatch(/New workspace/);
  });
});
