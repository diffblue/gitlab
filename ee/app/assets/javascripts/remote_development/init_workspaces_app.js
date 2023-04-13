import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './pages/app.vue';
import createRouter from './router';
import userWorkspacesListQuery from './graphql/queries/user_workspaces_list.query.graphql';

Vue.use(VueApollo);

const createApolloProvider = () => {
  const defaultClient = createDefaultClient();
  // what: Dummy data to support development
  defaultClient.cache.writeQuery({
    query: userWorkspacesListQuery,
    data: {
      userWorkspacesList: {
        nodes: [
          {
            id: 1,
            // eslint-disable-next-line @gitlab/require-i18n-strings
            name: 'Workspace 1',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            namespace: 'Namespace',
            projectFullPath: 'GitLab.org / GitLab',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            desiredState: 'Running',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            actualState: 'Started',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            displayedState: 'Started',
            url: 'https://127.0.0.1',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            editor: 'VSCode',
            devfile: 'devfile',
            branch: 'master',
            lastUsed: '2020-01-01T00:00:00.000Z',
          },
        ],
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
