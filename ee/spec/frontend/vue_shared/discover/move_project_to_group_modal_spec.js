import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MovePersonalProjectToGroupModal from 'ee/projects/components/move_personal_project_to_group_modal.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';

Vue.use(VueApollo);

describe('Move project to group modal', () => {
  let wrapper;
  const projectName = 'Example project';

  const createComponent = () => {
    wrapper = extendedWrapper(
      shallowMount(MovePersonalProjectToGroupModal, {
        propsData: { projectName },
        stubs: { GlSprintf },
      }),
    );
  };

  const moveProjectModal = () => wrapper.findComponent(GlModal);
  const findPrimaryAction = () => moveProjectModal().props('actionPrimary');

  describe('MovePersonalProjectToGroupModal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders component properly', () => {
      expect(moveProjectModal().exists()).toBe(true);
    });

    it('has a proper title', () => {
      expect(moveProjectModal().props('title')).toBe(
        `Your project ${projectName} is not in a group`,
      );
    });

    it('has proper content', () => {
      expect(moveProjectModal().text()).toContain(
        `${projectName} is a personal project, so none of this is available.`,
      );
      expect(moveProjectModal().element.innerHTML).toContain(
        'We have some instructions to help you create a group and move your project into it.',
      );
    });

    it('shows button and links to proper docs', () => {
      expect(findPrimaryAction().text).toBe('Learn to move a project to a group');
      expect(findPrimaryAction().attributes.href).toBe(
        helpPagePath('tutorials/move_personal_project_to_a_group'),
      );
    });
  });
});
