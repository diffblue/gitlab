import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './pages/app.vue';
import createRouter from './router/index';
import userWorkspacesListQuery from './graphql/queries/user_workspaces_list.query.graphql';
import { WORKSPACE_STATES, WORKSPACE_DESIRED_STATES } from './constants';

Vue.use(VueApollo);

const generateDummyWorkspace = (actualState, desiredState, createdAt = new Date()) => {
  const id = Math.random(0, 100000).toString(16).substring(0, 9);

  return {
    id: `gid://gitlab/RemoteDevelopment::Workspace/${id}`,
    name: `workspace-1-1-${id}`,
    namespace: `gl-rd-ns-1-1-${id}`,
    url: 'http://8000-workspace-1-1-idmi02.workspaces.localdev.me?tkn=password',
    devfileRef: 'main',
    devfilePath: '.devfile.yaml',
    actualState,
    desiredState,
    createdAt: createdAt.toISOString(),
    projectId: 'gid://gitlab/Project/2',
  };
};

const createApolloProvider = () => {
  const defaultClient = createDefaultClient({
    Mutation: {
      workspaceCreate: () => {
        return {
          workspace: generateDummyWorkspace(
            WORKSPACE_STATES.creationRequested,
            WORKSPACE_STATES.running,
          ),
          errors: [],
        };
      },
    },
  });
  // what: Dummy data to support development
  defaultClient.cache.writeQuery({
    query: userWorkspacesListQuery,
    data: {
      currentUser: {
        id: 1,
        workspaces: {
          nodes: [
            generateDummyWorkspace(WORKSPACE_STATES.running, WORKSPACE_DESIRED_STATES.running),
            generateDummyWorkspace(
              WORKSPACE_STATES.creationRequested,
              WORKSPACE_DESIRED_STATES.restartRequested,
            ),
            generateDummyWorkspace(WORKSPACE_STATES.starting, WORKSPACE_DESIRED_STATES.stopped),
            generateDummyWorkspace(
              WORKSPACE_STATES.terminating,
              WORKSPACE_DESIRED_STATES.terminated,
            ),
            generateDummyWorkspace(WORKSPACE_STATES.stopped, WORKSPACE_DESIRED_STATES.terminated),
            generateDummyWorkspace(WORKSPACE_STATES.stopping, WORKSPACE_DESIRED_STATES.running),
            generateDummyWorkspace(WORKSPACE_STATES.terminated, WORKSPACE_DESIRED_STATES.running),
            generateDummyWorkspace(
              WORKSPACE_STATES.terminated,
              WORKSPACE_DESIRED_STATES.running,
              new Date(2023, 0, 1),
            ),
            generateDummyWorkspace(WORKSPACE_STATES.failed, WORKSPACE_DESIRED_STATES.running),
            generateDummyWorkspace(WORKSPACE_STATES.error, WORKSPACE_DESIRED_STATES.running),
          ],
        },
      },
    },
  });

  return new VueApollo({ defaultClient });
};

const initWorkspacesApp = () => {
  const el = document.querySelector('#js-workspaces');

  if (!el) {
    return null;
  }

  const { workspacesListPath, emptyStateSvgPath } = el.dataset;
  const router = createRouter({
    base: workspacesListPath,
  });

  return new Vue({
    el,
    name: 'WorkspacesRoot',
    router,
    apolloProvider: createApolloProvider(),
    provide: {
      workspacesListPath,
      emptyStateSvgPath,
    },
    render: (createElement) => createElement(App),
  });
};

export { initWorkspacesApp };
