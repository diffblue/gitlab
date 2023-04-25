import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './pages/app.vue';
import createRouter from './router/index';
import userWorkspacesListQuery from './graphql/queries/user_workspaces_list.query.graphql';

Vue.use(VueApollo);

const createApolloProvider = () => {
  const defaultClient = createDefaultClient();
  // what: Dummy data to support development
  defaultClient.cache.writeQuery({
    query: userWorkspacesListQuery,
    data: {
      user: {
        id: 1,
        workspaces: {
          nodes: [
            {
              id: 'gid://gitlab/RemoteDevelopment::Workspace/2',
              name: 'workspace-1-1-idmi02',
              namespace: 'gl-rd-ns-1-1-idmi02',
              // eslint-disable-next-line @gitlab/require-i18n-strings
              desiredState: 'Stopped',
              // eslint-disable-next-line @gitlab/require-i18n-strings
              actualState: 'Creating',
              url: 'http://8000-workspace-1-1-idmi02.workspaces.localdev.me?tkn=password',
              devfileRef: 'main',
              devfilePath: '.devfile.yaml',
              project: {
                id: 'gid://gitlab/Project/2',
                // eslint-disable-next-line @gitlab/require-i18n-strings
                nameWithNamespace: 'Gitlab Shell',
              },
            },
            {
              id: 'gid://gitlab/RemoteDevelopment::Workspace/1',
              name: 'workspace-1-1-rfu27q',
              namespace: 'gl-rd-ns-1-1-rfu27q',
              // eslint-disable-next-line @gitlab/require-i18n-strings
              desiredState: 'Running',
              // eslint-disable-next-line @gitlab/require-i18n-strings
              actualState: 'Running',
              url: 'http://8000-workspace-1-1-rfu27q.workspaces.localdev.me?tkn=password',
              devfileRef: 'main',
              devfilePath: '.devfile.yaml',
              project: {
                id: 'gid://gitlab/Project/2',
                // eslint-disable-next-line @gitlab/require-i18n-strings
                nameWithNamespace: 'Gitlab Shell',
              },
            },
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
      currentUsername: window.gon.current_usernanme,
    },
    render: (createElement) => createElement(App),
  });
};

export { initWorkspacesApp };
