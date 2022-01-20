import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from 'ee/environments_dashboard/components/dashboard/project_header.vue';
import ProjectAvatar from '~/vue_shared/components/deprecated_project_avatar/default.vue';

describe('Project Header', () => {
  let wrapper;
  let propsData;

  beforeEach(() => {
    propsData = {
      project: {
        namespace: {
          name: 'hello',
          full_path: 'hello',
        },
        name: 'world',
        remove_path: '/hello/world/remove',
      },
    };
  });

  beforeEach(() => {
    wrapper = shallowMount(component, {
      propsData,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('renders project namespace, name, and avatars', () => {
    it('shows the project namespace avatar', () => {
      const projectNamespaceAvatar = wrapper.findAllComponents(ProjectAvatar).at(0);
      expect(projectNamespaceAvatar.props('project')).toEqual(propsData.project.namespace);
    });

    it('shows the project namespace', () => {
      expect(wrapper.find('.js-namespace').text()).toBe(propsData.project.namespace.name);
    });

    it('links to the project namespace', () => {
      const expectedUrl = `/${propsData.project.namespace.full_path}`;
      expect(wrapper.find('.js-namespace-link').attributes('href')).toBe(expectedUrl);
    });

    it('shows the project avatar', () => {
      const projectAvatar = wrapper.findAllComponents(ProjectAvatar).at(1);
      expect(projectAvatar.props('project')).toEqual(propsData.project);
    });

    it('shows the project name', () => {
      expect(wrapper.find('.js-name').text()).toBe(propsData.project.name);
    });

    it('links to the project', () => {
      expect(wrapper.find('.js-project-link').attributes('href')).toBe(propsData.project.web_url);
    });
  });

  describe('more actions', () => {
    it('should list "remove" as an action', () => {
      const removeLink = wrapper
        .findComponent(GlDropdown)
        .findAllComponents(GlDropdownItem)
        .filter((w) => w.text() === 'Remove');
      expect(removeLink.exists()).toBe(true);
    });

    it('should emit a "remove" event when "remove" is clicked', () => {
      const removeLink = wrapper
        .findComponent(GlDropdown)
        .findAllComponents(GlDropdownItem)
        .filter((w) => w.text() === 'Remove');
      removeLink.at(0).vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('remove')).toContainEqual([propsData.project.remove_path]);
      });
    });
  });
});
