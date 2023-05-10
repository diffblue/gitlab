import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import { GlBadge, GlFormSelect, GlForm, GlFormInput, GlLink, GlSprintf } from '@gitlab/ui';
import SearchProjectsListbox from 'ee/remote_development/components/create/search_projects_listbox.vue';
import WorkspaceCreate, { i18n } from 'ee/remote_development/pages/create.vue';
import GetProjectDetailsQuery from 'ee/remote_development/components/create/get_project_details_query.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  DEFAULT_EDITOR,
  DEFAULT_DESIRED_STATE,
  DEFAULT_DEVFILE_PATH,
  ROUTES,
  PROJECT_VISIBILITY,
  WORKSPACES_LIST_PAGE_SIZE,
} from 'ee/remote_development/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { logError } from '~/lib/logger';
import { createAlert } from '~/alert';
import workspaceCreateMutation from 'ee/remote_development/graphql/mutations/workspace_create.mutation.graphql';
import userWorkspacesQuery from 'ee/remote_development/graphql/queries/user_workspaces_list.query.graphql';
import {
  GET_PROJECT_DETAILS_QUERY_RESULT,
  USER_WORKSPACES_QUERY_RESULT,
  WORKSPACE_QUERY_RESULT,
  WORKSPACE_CREATE_MUTATION_RESULT,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/logger');
jest.mock('~/alert');

describe('remote_development/pages/create.vue', () => {
  const selectedProjectFixture = {
    fullPath: 'gitlab-org/gitlab',
    nameWithNamespace: 'GitLab Org / GitLab',
  };
  const selectedClusterAgentIDFixture = 'agents/1';
  const clusterAgentsFixture = [{ text: 'Agent', value: 'agents/1' }];
  const rootRefFixture = 'main';
  const GlFormSelectStub = stubComponent(GlFormSelect, {
    props: ['options'],
  });
  const mockRouter = {
    push: jest.fn(),
  };
  let wrapper;
  let workspaceCreateMutationHandler;
  let mockApollo;

  const buildMockApollo = () => {
    workspaceCreateMutationHandler = jest.fn();
    workspaceCreateMutationHandler.mockResolvedValueOnce(WORKSPACE_CREATE_MUTATION_RESULT);
    mockApollo = createMockApollo([[workspaceCreateMutation, workspaceCreateMutationHandler]]);
  };

  const readCachedWorkspaces = () => {
    const apolloClient = mockApollo.clients.defaultClient;
    const result = apolloClient.readQuery({
      query: userWorkspacesQuery,
      variables: {
        before: null,
        after: null,
        first: WORKSPACES_LIST_PAGE_SIZE,
      },
    });

    return result?.currentUser.workspaces.nodes;
  };

  const writeCachedWorkspaces = (workspaces) => {
    const apolloClient = mockApollo.clients.defaultClient;
    apolloClient.writeQuery({
      query: userWorkspacesQuery,
      variables: {
        before: null,
        after: null,
        first: WORKSPACES_LIST_PAGE_SIZE,
      },
      data: {
        currentUser: {
          ...USER_WORKSPACES_QUERY_RESULT.data.currentUser,
          workspaces: {
            nodes: workspaces,
            pageInfo: USER_WORKSPACES_QUERY_RESULT.data.currentUser.workspaces.pageInfo,
          },
        },
      },
    });
  };

  const createWrapper = () => {
    wrapper = shallowMountExtended(WorkspaceCreate, {
      apolloProvider: mockApollo,
      stubs: {
        GlFormSelect: GlFormSelectStub,
        GlSprintf,
      },
      mocks: {
        $router: mockRouter,
      },
    });
  };

  const findSearchProjectsListbox = () => wrapper.findComponent(SearchProjectsListbox);
  const findNoAgentsGlAlert = () => wrapper.findByTestId('no-agents-alert');
  const findNoDevFileGlAlert = () => wrapper.findByTestId('no-dev-file-alert');
  const findCreateWorkspaceErrorGlAlert = () =>
    wrapper.findByTestId('create-workspace-error-alert');
  const findClusterAgentsFormGroup = () =>
    wrapper.findByTestId('workspace-cluster-agent-form-group');
  const findGetProjectDetailsQuery = () => wrapper.findComponent(GetProjectDetailsQuery);
  const findCreateWorkspaceButton = () => wrapper.findByTestId('create-workspace');
  const findClusterAgentsFormSelect = () => wrapper.findComponent(GlFormSelectStub);
  const findMaxHoursBeforeTerminationField = () => wrapper.findComponent(GlFormInput);
  const emitGetProjectDetailsQueryResult = ({
    clusterAgents = [],
    hasDevFile = false,
    groupPath = GET_PROJECT_DETAILS_QUERY_RESULT.data.project.group.fullPath,
    id = GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
    rootRef = rootRefFixture,
  }) =>
    findGetProjectDetailsQuery().vm.$emit('result', {
      clusterAgents,
      hasDevFile,
      groupPath,
      rootRef,
      id,
    });
  const selectProject = (project = selectedProjectFixture) =>
    findSearchProjectsListbox().vm.$emit('input', project);
  const selectClusterAgent = () =>
    findClusterAgentsFormSelect().vm.$emit('input', selectedClusterAgentIDFixture);
  const submitCreateWorkspaceForm = () =>
    wrapper.findComponent(GlForm).vm.$emit('submit', { preventDefault: jest.fn() });

  beforeEach(() => {
    buildMockApollo();
  });

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('limits projects search to public projects', () => {
      expect(findSearchProjectsListbox().props().visibility).toBe(PROJECT_VISIBILITY.public);
    });

    it('displays a cancel button that allows navigating to the workspaces list', () => {
      expect(wrapper.findByTestId('cancel-workspace').attributes().to).toBe(ROUTES.index);
    });

    it('disables create workspace button', () => {
      expect(findCreateWorkspaceButton().props().disabled).toBe(true);
    });
  });

  describe('when a project does not have cluster agents', () => {
    beforeEach(async () => {
      createWrapper();

      await selectProject();
      await emitGetProjectDetailsQueryResult({ clusterAgents: [] });
    });

    it('displays danger alert indicating it', () => {
      expect(findNoAgentsGlAlert().props()).toMatchObject({
        title: i18n.invalidProjectAlert.title,
        variant: 'danger',
        dismissible: false,
      });
    });

    it('displays a link that navigates to the workspaces documentation', () => {
      expect(wrapper.findComponent(GlLink).attributes().href).toBe(
        '/help/user/workspace/index.md#configure-the-gitlab-agent-for-kubernetes',
      );
    });

    it('does not display cluster agents form select group', () => {
      expect(findClusterAgentsFormGroup().exists()).toBe(false);
    });

    it('does not display max hours before termination field', () => {
      expect(findMaxHoursBeforeTerminationField().exists()).toBe(false);
    });

    describe('when a project does not have a .devfile file', () => {
      it('does not display a devfile alert', async () => {
        createWrapper();

        await selectProject();
        await emitGetProjectDetailsQueryResult({
          hasDevFile: false,
        });

        expect(findNoDevFileGlAlert().exists()).toBe(false);
      });
    });
  });

  describe('when a project has cluster agents', () => {
    beforeEach(async () => {
      createWrapper();

      await selectProject();
      await emitGetProjectDetailsQueryResult({ clusterAgents: clusterAgentsFixture });
    });

    it('does not display danger alert', () => {
      expect(findNoAgentsGlAlert().exists()).toBe(false);
    });

    it('displays cluster agents form select group', () => {
      expect(findClusterAgentsFormGroup().exists()).toBe(true);
    });

    it('populates cluster agents form select with cluster agents', () => {
      expect(findClusterAgentsFormSelect().props().options).toBe(clusterAgentsFixture);
    });

    describe('when a project have a .devfile file', () => {
      it('does not display a devfile alert', async () => {
        createWrapper();

        await selectProject();
        await emitGetProjectDetailsQueryResult({
          hasDevFile: true,
          clusterAgents: clusterAgentsFixture,
        });

        expect(findNoDevFileGlAlert().exists()).toBe(false);
      });
    });

    describe('when a project does not have a .devfile file', () => {
      it('displays a devfile alert', async () => {
        createWrapper();

        await selectProject();
        await emitGetProjectDetailsQueryResult({
          hasDevFile: false,
          clusterAgents: clusterAgentsFixture,
        });

        expect(findNoDevFileGlAlert().props()).toMatchObject({
          title: i18n.invalidProjectAlert.title,
          variant: 'danger',
          dismissible: false,
        });
      });

      it('disables the "Create Workspace" button', () => {
        expect(findCreateWorkspaceButton().props().disabled).toBe(true);
      });
    });
  });

  describe('when a project and a cluster agent are selected and the project has a devfile', () => {
    beforeEach(async () => {
      createWrapper();

      await selectProject();
      await emitGetProjectDetailsQueryResult({
        clusterAgents: clusterAgentsFixture,
        hasDevFile: true,
      });
      await selectClusterAgent();
    });

    it('enables create workspace button', () => {
      expect(findCreateWorkspaceButton().props().disabled).toBe(false);
    });

    describe('when selecting a project again', () => {
      beforeEach(async () => {
        await selectProject({ nameWithNamespace: 'New Project', fullPath: 'new-project' });
      });

      it('cleans the selected cluster agent', () => {
        expect(findClusterAgentsFormGroup().exists()).toBe(false);
      });
    });

    describe('when clicking Create Workspace button', () => {
      it('submits workspaceCreate mutation', async () => {
        const maxHoursBeforeTermination = 10;

        findMaxHoursBeforeTerminationField().vm.$emit(
          'input',
          maxHoursBeforeTermination.toString(),
        );

        await nextTick();
        await submitCreateWorkspaceForm();

        expect(workspaceCreateMutationHandler).toHaveBeenCalledWith({
          input: {
            clusterAgentId: selectedClusterAgentIDFixture,
            projectId: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
            editor: DEFAULT_EDITOR,
            desiredState: DEFAULT_DESIRED_STATE,
            devfilePath: DEFAULT_DEVFILE_PATH,
            maxHoursBeforeTermination,
            devfileRef: rootRefFixture,
          },
        });
      });

      it('sets Create Workspace button as loading', async () => {
        await submitCreateWorkspaceForm();

        expect(findCreateWorkspaceButton().props().loading).toBe(true);
      });

      describe('when the workspaceCreate mutation succeeds', () => {
        it('when workspaces are not previously cached, does not update cache', async () => {
          await submitCreateWorkspaceForm();
          await waitForPromises();

          expect(readCachedWorkspaces()).toBeUndefined();
        });

        it('when workspaces are previously cached, updates cache', async () => {
          const originalWorkspace = WORKSPACE_QUERY_RESULT.data.workspace;
          writeCachedWorkspaces([originalWorkspace]);

          await submitCreateWorkspaceForm();
          await waitForPromises();

          expect(readCachedWorkspaces()).toEqual([
            WORKSPACE_CREATE_MUTATION_RESULT.data.workspaceCreate.workspace,
            originalWorkspace,
          ]);
        });

        it('redirects the user to the workspaces list', async () => {
          await submitCreateWorkspaceForm();
          await waitForPromises();

          expect(mockRouter.push).toHaveBeenCalledWith(ROUTES.index);
        });
      });

      describe('when the workspaceCreate mutation returns an error response', () => {
        it('displays an alert that contains the error response', async () => {
          const customMutationResponse = cloneDeep(WORKSPACE_CREATE_MUTATION_RESULT);
          const error = 'error response';

          customMutationResponse.data.workspaceCreate.workspace = null;
          customMutationResponse.data.workspaceCreate.errors.push(error);

          workspaceCreateMutationHandler.mockReset();
          workspaceCreateMutationHandler.mockResolvedValueOnce(customMutationResponse);

          await submitCreateWorkspaceForm();
          await waitForPromises();

          expect(findCreateWorkspaceErrorGlAlert().text()).toContain(error);
        });
      });

      describe('when the workspaceCreate mutation fails', () => {
        beforeEach(async () => {
          workspaceCreateMutationHandler.mockReset();
          workspaceCreateMutationHandler.mockRejectedValueOnce(new Error());

          await submitCreateWorkspaceForm();
          await waitForPromises();
        });

        it('logs error', () => {
          expect(logError).toHaveBeenCalled();
        });

        it('sets Create Workspace button as not loading', () => {
          expect(findCreateWorkspaceButton().props().loading).toBe(false);
        });

        it('displays alert indicating that creating a workspace failed', () => {
          expect(findCreateWorkspaceErrorGlAlert().text()).toContain(
            i18n.createWorkspaceFailedMessage,
          );
        });

        describe('when dismissing the create workspace error alert', () => {
          it('hides the workspace error alert', async () => {
            findCreateWorkspaceErrorGlAlert().vm.$emit('dismiss');
            await nextTick();

            expect(findCreateWorkspaceErrorGlAlert().exists()).toBe(false);
          });
        });
      });
    });
  });

  describe('when fetching project details fails', () => {
    beforeEach(() => {
      createWrapper();

      wrapper.findComponent(GetProjectDetailsQuery).vm.$emit('error');
    });

    it('displays alert indicating that fetching project details failed', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: i18n.fetchProjectDetailsFailedMessage });
    });
  });

  describe('fixed elements', () => {
    beforeEach(async () => {
      createWrapper();

      await waitForPromises();
    });

    it('displays a beta badge', () => {
      expect(wrapper.findComponent(GlBadge).props().variant).toBe('info');
    });
  });
});
