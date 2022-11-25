<script>
import { GlAlert, GlButton, GlDropdown, GlModal, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import linkSecurityPolicyProject from '../../graphql/mutations/link_security_policy_project.mutation.graphql';
import unlinkSecurityPolicyProject from '../../graphql/mutations/unlink_security_policy_project.mutation.graphql';
import InstanceProjectSelector from '../instance_project_selector.vue';
import {
  POLICY_PROJECT_LINK_ERROR_MESSAGE,
  POLICY_PROJECT_LINK_SUCCESS_MESSAGE,
} from './constants';

export default {
  PROJECT_SELECTOR_HEIGHT: 204,
  i18n: {
    modal: {
      okTitle: __('Save'),
      header: s__('SecurityOrchestration|Select security project'),
    },
    save: {
      okLink: POLICY_PROJECT_LINK_SUCCESS_MESSAGE,
      okUnlink: s__('SecurityOrchestration|Security policy project was unlinked successfully'),
      errorLink: POLICY_PROJECT_LINK_ERROR_MESSAGE,
      errorUnlink: s__(
        'SecurityOrchestration|An error occurred unassigning your security policy project',
      ),
    },
    unlinkButtonLabel: s__('SecurityOrchestration|Unlink project'),
    unlinkWarning: s__(
      'SecurityOrchestration|Unlinking a security project removes all policies stored in the linked security project. Save to confirm this action.',
    ),
    disabledWarning: s__('SecurityOrchestration|Only owners can update Security Policy Project'),
    description: s__(
      'SecurityOrchestration|Select a project to store your security policies in. %{linkStart}More information.%{linkEnd}',
    ),
    emptyPlaceholder: s__('SecurityOrchestration|Choose a project'),
  },
  components: {
    GlAlert,
    GlButton,
    GlDropdown,
    GlModal,
    GlSprintf,
    InstanceProjectSelector,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'disableSecurityPolicyProject',
    'documentationPath',
    'namespacePath',
    'assignedPolicyProject',
  ],
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      previouslySelectedProject: {},
      selectedProject: { ...this.assignedPolicyProject },
      hasSelectedNewProject: false,
      shouldShowUnlinkWarning: false,
      savingChanges: false,
    };
  },
  computed: {
    dropdownText() {
      return this.selectedProjectName || this.$options.i18n.emptyPlaceholder;
    },
    selectedProjects() {
      return [this.selectedProject];
    },
    selectedProjectId() {
      return this.selectedProject?.id || '';
    },
    selectedProjectName() {
      return this.selectedProject?.name || '';
    },
    isModalOkButtonDisabled() {
      if (this.shouldShowUnlinkWarning) {
        return false;
      }

      return this.disableSecurityPolicyProject || !this.hasSelectedNewProject;
    },
  },
  methods: {
    async linkProject() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: linkSecurityPolicyProject,
          variables: {
            input: {
              fullPath: this.namespacePath,
              securityPolicyProjectId: this.selectedProjectId,
            },
          },
        });

        if (data?.securityPolicyProjectAssign?.errors?.length) {
          throw new Error(data.securityPolicyProjectAssign.errors);
        }

        this.previouslySelectedProject = this.selectedProject;

        this.$emit('project-updated', {
          text: this.$options.i18n.save.okLink,
          variant: 'success',
          hasPolicyProject: true,
        });
      } catch {
        this.$emit('project-updated', {
          text: this.$options.i18n.save.errorLink,
          variant: 'danger',
          hasPolicyProject: false,
        });
      }
    },

    async unlinkProject() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: unlinkSecurityPolicyProject,
          variables: {
            input: {
              fullPath: this.namespacePath,
            },
          },
        });

        if (data?.securityPolicyProjectUnassign?.errors?.length) {
          throw new Error(data.securityPolicyProjectUnassign.errors);
        }

        this.shouldShowUnlinkWarning = false;
        this.previouslySelectedProject = {};
        this.$emit('project-updated', {
          text: this.$options.i18n.save.okUnlink,
          variant: 'success',
          hasPolicyProject: false,
        });
      } catch {
        this.$emit('project-updated', {
          text: this.$options.i18n.save.errorUnlink,
          variant: 'danger',
          hasPolicyProject: true,
        });
      }
    },

    async saveChanges() {
      this.savingChanges = true;
      this.$emit('updating-project');

      if (this.shouldShowUnlinkWarning) {
        await this.unlinkProject();
      } else {
        await this.linkProject();
      }

      this.savingChanges = false;
    },
    setSelectedProject(data) {
      this.shouldShowUnlinkWarning = false;
      this.hasSelectedNewProject = true;
      this.selectedProject = data;
      this.$refs.dropdown.hide();
    },
    confirmDeletion() {
      this.shouldShowUnlinkWarning = true;
      this.selectedProject = {};
      this.hasSelectedNewProject = true;
    },
    restoreProject() {
      this.selectedProject = this.previouslySelectedProject;
    },
    closeModal() {
      if (this.hasSelectedNewProject && !this.savingChanges) {
        this.restoreProject();
      }

      this.hasSelectedNewProject = false;
      this.shouldShowUnlinkWarning = false;
      this.$emit('close');
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$attrs"
    ref="modal"
    cancel-variant="light"
    size="sm"
    modal-id="scan-new-policy"
    :scrollable="false"
    :ok-title="$options.i18n.modal.okTitle"
    :title="$options.i18n.modal.header"
    :ok-disabled="isModalOkButtonDisabled"
    :visible="visible"
    @ok="saveChanges"
    @change="closeModal"
  >
    <div>
      <gl-alert
        v-if="disableSecurityPolicyProject"
        class="gl-mb-4"
        variant="warning"
        :dismissible="false"
      >
        {{ $options.i18n.disabledWarning }}
      </gl-alert>
      <gl-alert
        v-if="shouldShowUnlinkWarning"
        class="gl-mb-4"
        variant="warning"
        :dismissible="false"
      >
        {{ $options.i18n.unlinkWarning }}
      </gl-alert>
      <div class="gl-display-flex gl-mb-3">
        <gl-dropdown
          ref="dropdown"
          v-gl-tooltip
          :title="dropdownText"
          class="gl-min-w-0 gl-flex-grow-1"
          menu-class="gl-w-full! gl-max-w-full!"
          toggle-class="gl-min-w-0"
          :disabled="disableSecurityPolicyProject"
          :text="dropdownText"
        >
          <instance-project-selector
            class="gl-w-full"
            :max-list-height="$options.PROJECT_SELECTOR_HEIGHT"
            :selected-projects="selectedProjects"
            @projectClicked="setSelectedProject"
          />
        </gl-dropdown>
        <gl-button
          v-if="selectedProjectId"
          icon="remove"
          class="gl-ml-3"
          :aria-label="$options.i18n.unlinkButtonLabel"
          @click="confirmDeletion"
        />
      </div>
      <div class="gl-pb-5">
        <gl-sprintf :message="$options.i18n.description">
          <template #link="{ content }">
            <gl-button class="gl-pb-1!" variant="link" :href="documentationPath" target="_blank">
              {{ content }}
            </gl-button>
          </template>
        </gl-sprintf>
      </div>
    </div>
  </gl-modal>
</template>
