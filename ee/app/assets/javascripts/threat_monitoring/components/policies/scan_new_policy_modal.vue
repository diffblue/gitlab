<script>
import { GlButton, GlDropdown, GlSprintf, GlAlert, GlModal } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import assignSecurityPolicyProject from '../../graphql/mutations/assign_security_policy_project.mutation.graphql';
import InstanceProjectSelector from '../instance_project_selector.vue';

export default {
  PROJECT_SELECTOR_HEIGHT: 204,
  i18n: {
    modal: {
      okTitle: __('Save'),
      header: s__('SecurityOrchestration|Select security project'),
    },
    save: {
      ok: s__('SecurityOrchestration|Security policy project was linked successfully'),
      error: s__('SecurityOrchestration|An error occurred assigning your security policy project'),
    },
    disabledWarning: s__('SecurityOrchestration|Only owners can update Security Policy Project'),
    description: s__(
      'SecurityOrchestration|Select a project to store your security policies in. %{linkStart}More information.%{linkEnd}',
    ),
  },
  components: {
    GlButton,
    GlDropdown,
    GlSprintf,
    GlModal,
    GlAlert,
    InstanceProjectSelector,
  },
  inject: [
    'disableSecurityPolicyProject',
    'documentationPath',
    'projectPath',
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
      selectedProject: { ...this.assignedPolicyProject },
      hasSelectedNewProject: false,
    };
  },
  computed: {
    selectedProjectId() {
      return this.selectedProject?.id || '';
    },
    selectedProjectName() {
      return this.selectedProject?.name || '';
    },
    isModalOkButtonDisabled() {
      return this.disableSecurityPolicyProject || !this.hasSelectedNewProject;
    },
  },
  methods: {
    async saveChanges() {
      this.$emit('updating-project');

      try {
        const { data } = await this.$apollo.mutate({
          mutation: assignSecurityPolicyProject,
          variables: {
            input: {
              projectPath: this.projectPath,
              securityPolicyProjectId: this.selectedProjectId,
            },
          },
        });

        if (data?.securityPolicyProjectAssign?.errors?.length) {
          throw new Error(data.securityPolicyProjectAssign.errors);
        }

        this.$emit('project-updated', { text: this.$options.i18n.save.ok, variant: 'success' });
      } catch {
        this.$emit('project-updated', { text: this.$options.i18n.save.error, variant: 'danger' });
      } finally {
        this.hasSelectedNewProject = false;
      }
    },
    setSelectedProject(data) {
      this.hasSelectedNewProject = true;
      this.selectedProject = data;
      this.$refs.dropdown.hide();
    },
    closeModal() {
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
      <gl-dropdown
        ref="dropdown"
        class="gl-w-full gl-pb-5"
        menu-class="gl-w-full! gl-max-w-full!"
        :disabled="disableSecurityPolicyProject"
        :text="selectedProjectName"
      >
        <instance-project-selector
          class="gl-w-full"
          :max-list-height="$options.PROJECT_SELECTOR_HEIGHT"
          :selected-projects="[selectedProject]"
          @projectClicked="setSelectedProject"
        />
      </gl-dropdown>
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
