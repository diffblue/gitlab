import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLink, GlTableLite } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORKSPACE } from '~/graphql_shared/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import workspaceUpdateMutation from 'ee/remote_development/graphql/mutations/workspace_update.mutation.graphql';
import WorkspacesTable, { i18n } from 'ee/remote_development/components/list/workspaces_table.vue';
import WorkspaceActions from 'ee/remote_development/components/list/workspace_actions.vue';
import WorkspaceStateIndicator from 'ee/remote_development/components/list/workspace_state_indicator.vue';
import { populateWorkspacesWithProjectNames } from 'ee/remote_development/services/utils';
import { WORKSPACE_STATES, WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';
import {
  USER_WORKSPACES_QUERY_RESULT,
  USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT,
  WORKSPACE_UPDATE_MUTATION_RESULT,
} from '../../mock_data';

jest.mock('~/lib/logger');

Vue.use(VueApollo);

const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';

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
const findWorkspaceActions = (tableRow) => tableRow.findComponent(WorkspaceActions);

describe('remote_development/components/list/workspaces_table.vue', () => {
  let wrapper;
  let workspaceUpdateMutationHandler;

  const createWrapper = ({
    workspaces = populateWorkspacesWithProjectNames(
      USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes,
      USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT.data.projects.nodes,
    ),
  } = {}) => {
    workspaceUpdateMutationHandler = jest.fn();
    workspaceUpdateMutationHandler.mockResolvedValueOnce(WORKSPACE_UPDATE_MUTATION_RESULT);

    const mockApollo = createMockApollo([
      [workspaceUpdateMutation, workspaceUpdateMutationHandler],
    ]);

    wrapper = mount(WorkspacesTable, {
      apolloProvider: mockApollo,
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
      propsData: {
        workspaces,
      },
    });
  };
  const setupMockTerminatedWorkspace = (extraData = {}) => {
    const customData = cloneDeep(USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes);
    const workspace = cloneDeep(customData[0]);

    customData.unshift({
      ...workspace,
      actualState: WORKSPACE_STATES.terminated,
      ...extraData,
    });

    return customData;
  };

  describe('default (with nodes)', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows table when workspaces are available', () => {
      expect(findTable(wrapper).exists()).toBe(true);
    });

    it('displays user workspaces correctly', () => {
      expect(findTableRowsAsData(wrapper)).toEqual(
        populateWorkspacesWithProjectNames(
          USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes,
          USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT.data.projects.nodes,
        ).map((x) => {
          return {
            nameText: `${x.projectName}   ${x.name}`,
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
          };
        }),
      );
    });

    describe('when the query returns terminated workspaces', () => {
      beforeEach(() => {
        createWrapper({ workspaces: setupMockTerminatedWorkspace() });
      });

      it('sorts the list to display terminated workspaces at the end of the list', () => {
        expect(findTableRowsAsData(wrapper).pop().workspaceState).toBe(WORKSPACE_STATES.terminated);
      });
    });
  });

  describe('workspace actions is clicked', () => {
    const TEST_WORKSPACE_IDX = 1;
    const TEST_DESIRED_STATE = WORKSPACE_DESIRED_STATES.terminated;

    let workspace;
    let workspaceActions;

    beforeEach(() => {
      createWrapper();

      const row = findTableRows(wrapper).at(TEST_WORKSPACE_IDX);

      workspace =
        USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes[TEST_WORKSPACE_IDX];
      workspaceActions = findWorkspaceActions(row);
    });

    it(`sets workspace desiredState using the workspaceUpdate mutation`, async () => {
      workspaceActions.vm.$emit('click', TEST_DESIRED_STATE);

      await waitForPromises();

      expect(workspaceUpdateMutationHandler).toHaveBeenCalledWith({
        input: {
          desiredState: TEST_DESIRED_STATE,
          id: convertToGraphQLId(TYPE_WORKSPACE, workspace.id),
        },
      });
    });

    describe('when the workspaceUpdate mutation returns an error response', () => {
      const errorMessage = 'Updating workspace failed';

      beforeEach(async () => {
        const errorResponse = cloneDeep(WORKSPACE_UPDATE_MUTATION_RESULT);

        errorResponse.data.workspaceUpdate.errors = [errorMessage];

        workspaceUpdateMutationHandler.mockReset();
        workspaceUpdateMutationHandler.mockResolvedValueOnce(errorResponse);

        workspaceActions.vm.$emit('click', TEST_DESIRED_STATE);

        await waitForPromises();
      });

      it('emits an updateFailed event', () => {
        expect(wrapper.emitted('updateFailed')[0]).toEqual([
          {
            error: errorMessage,
          },
        ]);
      });
    });

    describe('when the workspaceUpdate mutation fails', () => {
      const error = new Error();

      beforeEach(async () => {
        workspaceUpdateMutationHandler.mockReset();
        workspaceUpdateMutationHandler.mockRejectedValueOnce(error);

        workspaceActions.vm.$emit('click', TEST_DESIRED_STATE);

        await waitForPromises();
      });

      it('emits an updateFailed event', () => {
        expect(wrapper.emitted('updateFailed')[0]).toEqual([
          {
            error: i18n.updateWorkspaceFailedMessage,
          },
        ]);
      });

      it('logs the error', () => {
        expect(logError).toHaveBeenCalledWith(error);
      });
    });
  });
});
