import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/remote_development/pages/app.vue';
import WorkspacesList from 'ee/remote_development/pages/list.vue';
import createRouter from 'ee/remote_development/router/index';
import CreateWorkspace from 'ee/remote_development/pages/create.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import userWorkspacesListQuery from 'ee/remote_development/graphql/queries/user_workspaces_list.query.graphql';
import userWorkspacesProjectsNamesQuery from 'ee/remote_development/graphql/queries/user_workspaces_projects_names.query.graphql';
import {
  USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT,
  USER_WORKSPACES_QUERY_EMPTY_RESULT,
} from '../mock_data';

Vue.use(VueRouter);
Vue.use(VueApollo);

const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';

describe('remote_development/router/index.js', () => {
  let router;
  let wrapper;

  beforeEach(() => {
    router = createRouter('/');
  });

  afterEach(() => {
    jest.restoreAllMocks();
    window.location.hash = '';
  });

  const mountApp = async (route = '/') => {
    await router.push(route);

    wrapper = mountExtended(App, {
      router,
      apolloProvider: createMockApollo([
        [userWorkspacesListQuery, jest.fn().mockResolvedValue(USER_WORKSPACES_QUERY_EMPTY_RESULT)],
        [
          userWorkspacesProjectsNamesQuery,
          jest.fn().mockResolvedValueOnce(USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT),
        ],
      ]),
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
      stubs: {
        SearchProjectsListbox: {
          template: '<div></div>',
        },
      },
    });
  };
  const findWorkspacesListPage = () => wrapper.findComponent(WorkspacesList);
  const findCreateWorkspacePage = () => wrapper.findComponent(CreateWorkspace);
  const findNewWorkspaceButton = () => wrapper.findByRole('link', { name: /New workspace/ });
  const findCreateWorkspaceCancelButton = () => wrapper.findByRole('link', { name: /Cancel/ });

  describe('root path', () => {
    beforeEach(async () => {
      await mountApp();
    });

    it('renders WorkspacesList on route /', () => {
      expect(findWorkspacesListPage().exists()).toBe(true);
    });

    it('navigates to /create when clicking New workspace button', async () => {
      await findNewWorkspaceButton().trigger('click');

      expect(findCreateWorkspacePage().exists()).toBe(true);
    });
  });

  describe('create path', () => {
    beforeEach(async () => {
      await mountApp('/create');
    });

    it('renders CreateWorkspace on route /create', () => {
      expect(findCreateWorkspacePage().exists()).toBe(true);
    });

    it('navigates to / when clicking Cancel button', async () => {
      await findCreateWorkspaceCancelButton().trigger('click');

      expect(findWorkspacesListPage().exists()).toBe(true);
    });
  });
});
