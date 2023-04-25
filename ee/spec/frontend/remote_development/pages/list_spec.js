import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlAlert, GlButton, GlLink, GlTableLite, GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkspaceList from 'ee/remote_development/pages/list.vue';
import WorkspaceEmptyState from 'ee/remote_development/components/list/empty_state.vue';
import userWorkspacesListQuery from 'ee/remote_development/graphql/queries/user_workspaces_list.query.graphql';
import { WORKSPACE_STATES, ROUTES } from 'ee/remote_development/constants';
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
      statusIcon: tds.at(0).findComponent(GlIcon).props('name'),
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

  const createWrapper = (mockData = USER_WORKSPACES_QUERY_RESULT) => {
    userWorkspacesListQueryHandler = jest.fn().mockResolvedValueOnce(mockData);

    const mockApollo = createMockApollo([
      [userWorkspacesListQuery, userWorkspacesListQueryHandler],
    ]);

    wrapper = mount(WorkspaceList, {
      apolloProvider: mockApollo,
      provide: {
        emptyStateSvgPath: SVG_PATH,
        currentUsername: CURRENT_USERNAME,
      },
    });
  };

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
        USER_WORKSPACES_QUERY_RESULT.data.user.workspaces.nodes.map((x) => {
          const workspaceData = {
            nameText: `${x.project.nameWithNamespace}   ${x.name}`,
            statusIcon: 'status-stopped',
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
