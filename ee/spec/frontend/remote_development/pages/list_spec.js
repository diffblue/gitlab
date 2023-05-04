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
import WorkspaceActions from 'ee/remote_development/components/list/workspace_actions.vue';
import WorkspaceEmptyState from 'ee/remote_development/components/list/empty_state.vue';
import WorkspaceStateIndicator from 'ee/remote_development/components/list/workspace_state_indicator.vue';
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
      actionsProps: tds.at(2).findComponent(WorkspaceActions).props(),
    };

    if (tds.at(1).findComponent(GlLink).exists()) {
      rowData.previewText = tds.at(1).text();
      rowData.previewHref = tds.at(1).findComponent(GlLink).attributes('href');
    }

    return rowData;
  });
const findNewWorkspaceButton = (wrapper) => wrapper.findComponent(GlButton);
const findWorkspaceActions = (tableRow) => tableRow.findComponent(WorkspaceActions);

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
        USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes.map((x) => ({
          nameText: `${x.projectId}   ${x.name}`,
          workspaceState: x.actualState,
          actionsProps: {
            actualState: x.actualState,
            desiredState: x.desiredState,
          },
          ...(x.actualState === WORKSPACE_STATES.running
            ? {
                previewText: x.url,
                previewHref: x.url,
              }
            : {}),
        })),
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

  describe('workspace actions is clicked', () => {
    const TEST_WORKSPACE_IDX = 1;
    const TEST_DESIRED_STATE = WORKSPACE_DESIRED_STATES.terminated;

    let workspace;
    let workspaceActions;

    beforeEach(async () => {
      createWrapper(USER_WORKSPACES_QUERY_RESULT);

      await waitForPromises();

      const row = findTableRows(wrapper).at(TEST_WORKSPACE_IDX);

      workspace =
        USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes[TEST_WORKSPACE_IDX];
      workspaceActions = findWorkspaceActions(row);
    });

    it(`sets workspace desiredState using the workspaceUpdate mutation`, async () => {
      workspaceActions.vm.$emit('click', TEST_DESIRED_STATE);

      await waitForPromises();

      expect(workspaceUpdateMutationHandler).toHaveBeenCalledWith(
        expect.any(Object),
        {
          input: {
            desiredState: TEST_DESIRED_STATE,
            id: convertToGraphQLId(TYPE_WORKSPACE, workspace.id),
          },
        },
        expect.any(Object),
        expect.any(Object),
      );
    });

    describe('when the workspaceUpdate mutation fails', () => {
      const error = new Error();

      beforeEach(async () => {
        workspaceUpdateMutationHandler.mockReset();
        workspaceUpdateMutationHandler.mockRejectedValueOnce(error);

        workspaceActions.vm.$emit('click', TEST_DESIRED_STATE);

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
