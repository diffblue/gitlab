<script>
import { GlAlert, GlButton, GlDropdown, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import assignSecurityPolicyProject from '../graphql/mutations/assign_security_policy_project.mutation.graphql';
import InstanceProjectSelector from './instance_project_selector.vue';

export default {
  PROJECT_SELECTOR_HEIGHT: 204,
  i18n: {
    assignError: s__(
      'SecurityOrchestration|An error occurred assigning your security policy project',
    ),
    assignSuccess: s__('SecurityOrchestration|Security policy project was linked successfully'),
    disabledButtonTooltip: s__(
      'SecurityOrchestration|Only owners can update Security Policy Project',
    ),
    securityProject: s__(
      'SecurityOrchestration|A security policy project can enforce policies for a given project, group, or instance. With a security policy project, you can specify security policies that are important to you and enforce them with every commit. %{linkStart}More information.%{linkEnd}',
    ),
  },
  components: {
    GlAlert,
    GlButton,
    GlDropdown,
    GlSprintf,
    InstanceProjectSelector,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['disableSecurityPolicyProject', 'documentationPath', 'projectPath'],
  props: {
    assignedPolicyProject: {
      type: Object,
      required: false,
      default: () => {
        return { id: '', name: '' };
      },
    },
  },
  data() {
    return {
      currentProjectId: this.assignedPolicyProject.id,
      selectedProject: this.assignedPolicyProject,
      isAssigningProject: false,
      showAssignError: false,
      showAssignSuccess: false,
    };
  },
  computed: {
    hasSelectedNewProject() {
      return this.currentProjectId !== this.selectedProject.id;
    },
  },
  methods: {
    dismissAlert(type) {
      this[type] = false;
    },
    async saveChanges() {
      this.isAssigningProject = true;
      this.showAssignError = false;
      this.showAssignSuccess = false;
      const { id } = this.selectedProject;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: assignSecurityPolicyProject,
          variables: {
            input: {
              projectPath: this.projectPath,
              securityPolicyProjectId: id,
            },
          },
        });
        if (data?.securityPolicyProjectAssign?.errors?.length) {
          this.showAssignError = true;
        } else {
          this.showAssignSuccess = true;
          this.currentProjectId = id;
        }
      } catch {
        this.showAssignError = true;
      } finally {
        this.isAssigningProject = false;
      }
    },
    setSelectedProject(data) {
      this.selectedProject = data;
      this.$refs.dropdown.hide(true);
    },
  },
};
</script>

<template>
  <section>
    <gl-alert
      v-if="showAssignError"
      class="gl-mt-3"
      data-testid="policy-project-assign-error"
      variant="danger"
      :dismissible="true"
      @dismiss="dismissAlert('showAssignError')"
    >
      {{ $options.i18n.assignError }}
    </gl-alert>
    <gl-alert
      v-else-if="showAssignSuccess"
      class="gl-mt-3"
      data-testid="policy-project-assign-success"
      variant="success"
      :dismissible="true"
      @dismiss="dismissAlert('showAssignSuccess')"
    >
      {{ $options.i18n.assignSuccess }}
    </gl-alert>
    <h2 class="gl-mb-8">
      {{ s__('SecurityOrchestration|Create a policy') }}
    </h2>
    <div class="gl-w-half">
      <h4>
        {{ s__('SecurityOrchestration|Security policy project') }}
      </h4>
      <gl-dropdown
        ref="dropdown"
        class="gl-w-full gl-pb-5 security-policy-dropdown"
        menu-class="gl-w-full! gl-max-w-full!"
        :disabled="disableSecurityPolicyProject"
        :text="selectedProject.name || ''"
      >
        <instance-project-selector
          class="gl-w-full"
          :max-list-height="$options.PROJECT_SELECTOR_HEIGHT"
          :selected-projects="[selectedProject]"
          @projectClicked="setSelectedProject"
        />
      </gl-dropdown>
      <div class="gl-pb-5">
        <gl-sprintf :message="$options.i18n.securityProject">
          <template #link="{ content }">
            <gl-button class="gl-pb-1!" variant="link" :href="documentationPath" target="_blank">
              {{ content }}
            </gl-button>
          </template>
        </gl-sprintf>
      </div>
      <span
        v-gl-tooltip="{
          disabled: !disableSecurityPolicyProject,
          title: $options.i18n.disabledButtonTooltip,
          placement: 'bottom',
        }"
        data-testid="disabled-button-tooltip"
      >
        <gl-button
          data-testid="save-policy-project"
          variant="confirm"
          :disabled="disableSecurityPolicyProject || !hasSelectedNewProject"
          :loading="isAssigningProject"
          @click="saveChanges"
        >
          {{ __('Save changes') }}
        </gl-button>
      </span>
    </div>
  </section>
</template>
