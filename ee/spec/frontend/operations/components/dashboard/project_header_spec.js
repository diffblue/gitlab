import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectHeader from 'ee/operations/components/dashboard/project_header.vue';
import { trimText } from 'helpers/text_helper';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { mockOneProject } from '../../mock_data';

describe('project header component', () => {
  let wrapper;

  const factory = () => {
    wrapper = shallowMountExtended(ProjectHeader, {
      propsData: {
        project: mockOneProject,
      },
    });
  };

  const findRemoveProjectButton = () => wrapper.findByTestId('remove-project-button');

  beforeEach(() => {
    factory();
  });

  it('renders project name with namespace', () => {
    const namespace = wrapper.findByTestId('project-namespace').text();
    const name = wrapper.findByTestId('project-name').text();

    expect(trimText(namespace).trim()).toBe(`${mockOneProject.namespace.name} /`);
    expect(trimText(name).trim()).toBe(mockOneProject.name);
  });

  it('links project name to project', () => {
    const path = mockOneProject.web_url;

    expect(wrapper.findByTestId('project-link').attributes('href')).toBe(path);
  });

  describe('remove button', () => {
    it('renders removal button icon', () => {
      expect(findRemoveProjectButton().props('icon')).toBe('close');
    });

    it('renders correct title for removal icon', () => {
      expect(findRemoveProjectButton().attributes('title')).toBe('Remove card');
    });

    it('emits project removal link on click', async () => {
      findRemoveProjectButton().vm.$emit('click');
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
        expect(wrapper.findComponent(ProjectAvatar).props()).toMatchObject({
          projectId: mockOneProject.id,
          projectName: mockOneProject.name,
          projectAvatarUrl: mockOneProject.avatar_url,
        });
      });
    });
  });
});
