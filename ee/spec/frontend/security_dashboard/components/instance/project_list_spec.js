import { GlBadge, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ProjectList from 'ee/security_dashboard/components/instance/project_list.vue';
import projectsQuery from 'ee/security_dashboard/graphql/queries/instance_projects.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

Vue.use(VueApollo);

const generateMockProjects = (count) => {
  const projects = [];

  for (let i = 0; i < count; i += 1) {
    projects.push({
      id: i,
      name: `project${i}`,
      nameWithNamespace: `group/project${i}`,
      avatarUrl: '/avatar',
    });
  }

  return projects;
};

describe('Project List component', () => {
  let wrapper;

  const getMockData = (projects) => ({
    data: {
      instance: {
        projects: {
          edges: projects.map((node) => ({ node })),
          pageInfo: { hasNextPage: false, endCursor: null },
        },
      },
    },
  });

  const createWrapper = ({ projects }) => {
    const mockData = getMockData(projects);

    wrapper = extendedWrapper(
      shallowMount(ProjectList, {
        apolloProvider: createMockApollo([[projectsQuery, jest.fn().mockResolvedValue(mockData)]]),
      }),
    );
  };

  const getAllProjectItems = () => wrapper.findAll('.js-projects-list-project-item');
  const getFirstProjectItem = () => wrapper.find('.js-projects-list-project-item');
  const getFirstRemoveButton = () => getFirstProjectItem().find('.js-projects-list-project-remove');
  const getLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  it('shows an empty state if there are no projects', async () => {
    createWrapper({ projects: [] });
    await waitForPromises();

    expect(wrapper.findByTestId('empty-message').exists()).toBe(true);
  });

  describe('loading indicator', () => {
    it('shows the loading indicator when query is loading', () => {
      createWrapper({ projects: [] });

      expect(getLoadingIcon().exists()).toBe(true);
    });

    it('hides the loading indicator when query is not loading', async () => {
      createWrapper({ projects: [] });
      await waitForPromises();

      expect(getLoadingIcon().exists()).toBe(false);
    });
  });

  it.each([0, 1, 2])(
    'renders a list of projects and displays the correct count for %s projects',
    async (projectsCount) => {
      createWrapper({ projects: generateMockProjects(projectsCount) });
      await waitForPromises();

      expect(getAllProjectItems()).toHaveLength(projectsCount);
      expect(wrapper.findComponent(GlBadge).text()).toBe(projectsCount.toString());
    },
  );

  describe('project item', () => {
    const projects = generateMockProjects(1);

    beforeEach(() => {
      createWrapper({ projects });
      return waitForPromises();
    });

    it('renders a project item with an avatar', () => {
      const projectAvatar = getFirstProjectItem().findComponent(ProjectAvatar);
      const project = projects[0];

      expect(projectAvatar.exists()).toBe(true);
      expect(projectAvatar.props()).toMatchObject({
        projectId: project.id,
        projectName: project.name,
        projectAvatarUrl: project.avatarUrl,
      });
    });

    it('renders a project item with a project name', () => {
      expect(getFirstProjectItem().text()).toContain(projects[0].nameWithNamespace);
    });

    it('renders a project item with a remove button', () => {
      expect(getFirstRemoveButton().exists()).toBe(true);
    });

    it(`emits a 'projectRemoved' event when a project's remove button has been clicked`, () => {
      getFirstRemoveButton().vm.$emit('click');

      expect(wrapper.emitted('projectRemoved')).toHaveLength(1);
      expect(wrapper.emitted('projectRemoved')[0][0]).toEqual(projects[0]);
    });
  });
});
