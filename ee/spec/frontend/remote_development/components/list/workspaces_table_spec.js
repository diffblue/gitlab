import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLink, GlTableLite } from '@gitlab/ui';
import WorkspacesTable from 'ee/remote_development/components/list/workspaces_table.vue';
import WorkspaceActions from 'ee/remote_development/components/common/workspace_actions.vue';
import WorkspaceStateIndicator from 'ee/remote_development/components/common/workspace_state_indicator.vue';
import { populateWorkspacesWithProjectNames } from 'ee/remote_development/services/utils';
import { WORKSPACE_STATES, WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';
import {
  USER_WORKSPACES_QUERY_RESULT,
  USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT,
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
  let updateWorkspaceMutationMock;
  const UpdateWorkspaceMutationStub = {
    render() {
      return this.$scopedSlots.default({ update: updateWorkspaceMutationMock });
    },
  };

  const createWrapper = ({
    workspaces = populateWorkspacesWithProjectNames(
      USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.nodes,
      USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT.data.projects.nodes,
    ),
  } = {}) => {
    updateWorkspaceMutationMock = jest.fn();
    wrapper = mount(WorkspacesTable, {
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
      propsData: {
        workspaces,
      },
      stubs: {
        UpdateWorkspaceMutation: UpdateWorkspaceMutationStub,
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
  const findUpdateWorkspaceMutation = () => wrapper.findComponent(UpdateWorkspaceMutationStub);

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
              compact: false,
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

  describe.each`
    event              | payload
    ${'updateFailed'}  | ${['error message']}
    ${'updateSucceed'} | ${[]}
  `('when updateWorspaceMutation triggers $event event', ({ event, payload }) => {
    it('bubbles up event', () => {
      createWrapper();

      expect(wrapper.emitted(event)).toBe(undefined);

      findUpdateWorkspaceMutation().vm.$emit(event, payload[0]);

      expect(wrapper.emitted(event)).toEqual([payload]);
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

      workspaceActions.vm.$emit('click', TEST_DESIRED_STATE);
    });

    it('calls the update method provided by the WorkspaceUpdateMutation component', () => {
      expect(updateWorkspaceMutationMock).toHaveBeenCalledWith(workspace.id, {
        desiredState: TEST_DESIRED_STATE,
      });
    });
  });
});
