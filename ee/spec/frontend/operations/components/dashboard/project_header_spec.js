import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ProjectHeader from 'ee/operations/components/dashboard/project_header.vue';
import { trimText } from 'helpers/text_helper';
import ProjectAvatar from '~/vue_shared/components/deprecated_project_avatar/default.vue';
import { mockOneProject } from '../../mock_data';

describe('project header component', () => {
  let wrapper;

  const factory = () => {
    wrapper = shallowMount(ProjectHeader, {
      propsData: {
        project: mockOneProject,
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders project name with namespace', () => {
    const namespace = wrapper.find('.js-project-namespace').text();
    const name = wrapper.find('.js-project-name').text();

    expect(trimText(namespace).trim()).toBe(`${mockOneProject.namespace.name} /`);
    expect(trimText(name).trim()).toBe(mockOneProject.name);
  });

  it('links project name to project', () => {
    const path = mockOneProject.web_url;

    expect(wrapper.find('.js-project-link').attributes('href')).toBe(path);
  });

  describe('remove button', () => {
    it('renders removal button icon', () => {
      expect(wrapper.find('.js-remove-button').exists()).toBe(true);
    });

    it('renders correct title for removal icon', () => {
      const button = wrapper.find('.js-remove-button');

      expect(button.attributes('title')).toBe('Remove card');
    });

    it('emits project removal link on click', async () => {
      wrapper.find('.js-remove-button').vm.$emit('click');

      await nextTick();
      expect(wrapper.emitted().remove).toStrictEqual([[mockOneProject.remove_path]]);
    });
  });

  describe('wrapped components', () => {
    describe('project avatar', () => {
      it('renders', () => {
        expect(wrapper.findAllComponents(ProjectAvatar)).toHaveLength(1);
      });

      it('binds project', () => {
        expect(wrapper.findComponent(ProjectAvatar).props('project')).toEqual(mockOneProject);
      });
    });
  });
});
