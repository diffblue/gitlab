import { GlLink, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DependencyProjectCount from 'ee/dependencies/components/dependency_project_count.vue';

describe('Dependency Project Count component', () => {
  let wrapper;

  const project = { full_path: 'full_path', name: 'project-name' };

  const createComponent = ({ propsData } = {}) => {
    wrapper = shallowMount(DependencyProjectCount, {
      propsData,
      stubs: { GlTruncate, GlLink },
    });
  };

  const findMainComponent = () => wrapper.find('[data-testid="dependency-project-count"]');

  describe('with a single project', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          projectCount: 1,
          project,
        },
      });
    });

    it('renders link to project path', () => {
      expect(findMainComponent().element.tagName).toBe('GLLINK-STUB');
      expect(findMainComponent().attributes('href')).toContain(project.full_path);
    });

    it('renders project name', () => {
      expect(wrapper.text()).toContain(project.name);
    });
  });

  describe('with multiple projects', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          projectCount: 2,
          project,
        },
      });
    });

    it('does not render a link', () => {
      expect(findMainComponent().element.tagName).toBe('SPAN');
      expect(findMainComponent().attributes('href')).toBe('');
    });

    it('renders project count instead project name', () => {
      expect(wrapper.text()).toContain('2 projects');
      expect(wrapper.text()).not.toContain(project.name);
    });
  });
});
