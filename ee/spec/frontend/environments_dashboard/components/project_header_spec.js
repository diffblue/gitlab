import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import component from 'ee/environments_dashboard/components/dashboard/project_header.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

const mockProject = {
  namespace: {
    id: 1,
    name: 'hello',
    full_path: 'hello',
    avatar_url: '/namespace-avatar',
  },
  id: 2,
  name: 'world',
  remove_path: '/hello/world/remove',
  avatar_url: '/project-avatar',
};

describe('Project Header', () => {
  let wrapper;

  const findRemoveButton = () =>
    wrapper
      .findComponent(GlDropdown)
      .findAllComponents(GlDropdownItem)
      .filter((w) => w.text() === 'Remove');

  beforeEach(() => {
    wrapper = shallowMountExtended(component, {
      propsData: { project: mockProject },
    });
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('renders project namespace, name, and avatars', () => {
    it('shows the project namespace avatar', () => {
      const projectNamespaceAvatar = wrapper.findAllComponents(ProjectAvatar).at(0);
      expect(projectNamespaceAvatar.props()).toMatchObject({
        projectId: mockProject.namespace.id,
        projectName: mockProject.namespace.name,
        projectAvatarUrl: mockProject.namespace.avatar_url,
      });
    });

    it('links to the project namespace', () => {
      const expectedUrl = `/${mockProject.namespace.full_path}`;
      const namespaceLink = wrapper.findByTestId('namespace-link');

      expect(namespaceLink.attributes('href')).toBe(expectedUrl);
      expect(namespaceLink.text()).toMatchInterpolatedText(mockProject.namespace.name);
    });

    it('shows the project avatar', () => {
      const projectAvatar = wrapper.findAllComponents(ProjectAvatar).at(1);
      expect(projectAvatar.props()).toMatchObject({
        projectId: mockProject.id,
        projectName: mockProject.name,
        projectAvatarUrl: mockProject.avatar_url,
      });
    });

    it('links to the project', () => {
      const projectLink = wrapper.findByTestId('project-link');

      expect(projectLink.attributes('href')).toBe(mockProject.web_url);
      expect(projectLink.text()).toMatchInterpolatedText(mockProject.name);
    });
  });

  describe('more actions', () => {
    it('should list "remove" as an action', () => {
      expect(findRemoveButton().exists()).toBe(true);
    });

    it('should emit a "remove" event when "remove" is clicked', async () => {
      findRemoveButton().at(0).vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('remove')).toContainEqual([mockProject.remove_path]);
    });
  });
});
