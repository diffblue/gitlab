import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import App from '~/organizations/groups_and_projects/components/app.vue';
import resolvers from '~/organizations/groups_and_projects/graphql/resolvers';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { organizationProjects } from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);
jest.useFakeTimers();

describe('GroupsAndProjectsApp', () => {
  let wrapper;
  let mockApollo;

  const createComponent = ({ mockResolvers = resolvers } = {}) => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMountExtended(App, { apolloProvider: mockApollo });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('when API call is loading', () => {
    beforeEach(() => {
      const mockResolvers = {
        Query: {
          organization: jest.fn().mockReturnValueOnce(new Promise(() => {})),
        },
      };

      createComponent({ mockResolvers });
    });

    it('renders loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when API call is successful', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders `ProjectsList` component and passes correct props', async () => {
      jest.runAllTimers();
      await waitForPromises();

      expect(wrapper.findComponent(ProjectsList).props()).toEqual({
        projects: organizationProjects.projects.nodes.map(
          ({ id, nameWithNamespace, accessLevel, ...project }) => ({
            ...project,
            id: getIdFromGraphQLId(id),
            name: nameWithNamespace,
            permissions: {
              projectAccess: {
                accessLevel: accessLevel.integerValue,
              },
            },
          }),
        ),
        showProjectIcon: true,
      });
    });
  });

  describe('when API call is not successful', () => {
    const error = new Error();

    beforeEach(() => {
      const mockResolvers = {
        Query: {
          organization: jest.fn().mockRejectedValueOnce(error),
        },
      };

      createComponent({ mockResolvers });
    });

    it('displays error alert', async () => {
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: App.i18n.errorMessage,
        error,
        captureError: true,
      });
    });
  });
});
