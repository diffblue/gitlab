import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink, GlTruncate, GlCollapsibleListbox, GlAvatar } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import DependencyProjectCount from 'ee/dependencies/components/dependency_project_count.vue';
import dependenciesProjectsQuery from 'ee/dependencies/graphql/projects.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

describe('Dependency Project Count component', () => {
  let wrapper;

  const projectName = 'project-name';
  const fullPath = 'top-level-group/project-name';
  const avatarUrl = 'url/avatar';

  const payload = {
    data: {
      group: {
        id: 1,
        projects: {
          nodes: [
            {
              avatarUrl,
              fullPath,
              id: 2,
              name: projectName,
            },
          ],
        },
      },
    },
  };

  const apolloResolver = jest.fn().mockResolvedValue(payload);

  const createComponent = ({ propsData, mountFn = shallowMount } = {}) => {
    const endpoint = 'groups/endpoint/-/dependencies.json';
    const project = { fullPath, name: projectName };

    const basicProps = {
      projectCount: 1,
      project,
      componentId: 1,
    };

    const handlers = [[dependenciesProjectsQuery, apolloResolver]];

    wrapper = mountFn(DependencyProjectCount, {
      apolloProvider: createMockApollo(handlers),
      propsData: { ...basicProps, ...propsData },
      provide: { endpoint },
      stubs: { GlLink, GlTruncate },
    });
  };

  const findProjectLink = () => wrapper.findComponent(GlLink);
  const findProjectAvatar = () => wrapper.findComponent(GlAvatar);
  const findProjectList = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('with a single project', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders link to project path', () => {
      expect(findProjectLink().exists()).toBe(true);
      expect(findProjectLink().attributes('href')).toContain(fullPath);
    });

    it('renders project name', () => {
      expect(findProjectLink().text()).toContain(projectName);
    });

    it('does not render listbox', () => {
      expect(findProjectList().exists()).toBe(false);
    });
  });

  describe('with multiple projects', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          projectCount: 2,
        },
      });
    });

    it('renders the listbox', () => {
      expect(findProjectList().props()).toMatchObject({
        headerText: '2 projects',
        searchable: true,
        items: [],
        loading: false,
        searching: false,
      });
    });

    it('renders project count instead project name', () => {
      expect(findProjectList().props('headerText')).toBe('2 projects');
    });

    describe('with fetched data', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            projectCount: 2,
          },
          mountFn: mount,
        });
      });

      it('sets searching based on the data being fetched', async () => {
        findProjectList().vm.$emit('shown');
        await waitForPromises();

        expect(apolloResolver).toHaveBeenCalled();
        expect(findProjectList().props('searching')).toBe(false);
      });

      it('sets searching when search term is updated', async () => {
        await findProjectList().vm.$emit('search', 'a');

        expect(findProjectList().props('searching')).toBe(true);

        await waitForPromises();

        expect(findProjectList().props('searching')).toBe(false);
      });

      describe('after the click event', () => {
        beforeEach(async () => {
          findProjectList().vm.$emit('shown');
          await waitForPromises();
        });

        it('displays project avatar', () => {
          expect(findProjectAvatar().props('src')).toBe(avatarUrl);
        });

        it('displays project name', () => {
          expect(findProjectLink().text()).toContain(projectName);
        });

        it('displays link to project dependencies', () => {
          expect(findProjectLink().attributes('href')).toBe(`/${fullPath}/-/dependencies`);
        });

        describe('with relative url root set', () => {
          beforeEach(async () => {
            gon.relative_url_root = '/relative_url';
            createComponent({
              propsData: {
                projectCount: 2,
              },
              mountFn: mount,
            });
            findProjectList().vm.$emit('shown');
            await waitForPromises();
          });

          it('displays link to project dependencies', () => {
            expect(findProjectLink().attributes('href')).toBe(
              `/relative_url/${fullPath}/-/dependencies`,
            );
          });
        });
      });
    });
  });
});
