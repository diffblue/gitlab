<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { MOVE_PERSONAL_PROJECT_TO_GROUP_MODAL } from 'ee/projects/constants';

export default {
  name: 'MovePersonalProjectToGroupModal',
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    projectName: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalTitle() {
      return sprintf(this.$options.i18n.modalTitle, {
        projectName: this.projectName,
      });
    },
    modalContentStartText() {
      return sprintf(this.$options.i18n.modalContentStartText, {
        projectName: this.projectName,
      });
    },
    actionPrimary() {
      return {
        text: this.$options.i18n.buttonLabel,
        attributes: {
          target: '_blank',
          category: 'primary',
          variant: 'info',
          href: this.$options.moveProjectDocsPath,
          'data-testid': 'docs-link-button',
        },
      };
    },
  },
  i18n: {
    modalTitle: s__('PersonalProject|Your project %{projectName} is not in a group'),
    buttonLabel: s__('PersonalProject|Learn to move a project to a group'),
  },
  moveProjectDocsPath: helpPagePath('tutorials/move_personal_project_to_a_group'),
  modalId: MOVE_PERSONAL_PROJECT_TO_GROUP_MODAL,
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modalId"
    size="sm"
    :action-primary="actionPrimary"
    :title="modalTitle"
    @primary.prevent
  >
    <gl-sprintf
      :message="
        s__(
          `PersonalProject|Some GitLab features, 
          including the ability to upgrade to a paid plan or start a free trial, 
          are only available for groups and projects inside groups. %{projectName} is a personal project, 
          so none of this is available. We recommend you move your project to a group to unlock GitLab's full potential.`,
        )
      "
    >
      <template #projectName>
        <span>{{ projectName }}</span>
      </template>
    </gl-sprintf>
    <br /><br />
    <gl-sprintf
      :message="
        s__(
          'PersonalProject|We have some instructions to help you create a group and move your project into it.',
        )
      "
    />
  </gl-modal>
</template>
