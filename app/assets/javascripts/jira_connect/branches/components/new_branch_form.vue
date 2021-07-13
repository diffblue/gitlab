<script>
import { GlFormGroup, GlButton, GlFormInput, GlForm, GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import createBranchMutation from '../graphql/mutations/create_branch.mutation.graphql';
import ProjectDropdown from './project_dropdown.vue';
import SourceBranchDropdown from './source_branch_dropdown.vue';

const DEFAULT_ALERT_VARIANT = 'danger';
const DEFAULT_ALERT_PARAMS = {
  title: '',
  message: '',
  variant: DEFAULT_ALERT_VARIANT,
  primaryButtonLink: '',
  primaryButtonText: '',
};

export default {
  name: 'JiraConnectNewBranch',
  components: {
    GlFormGroup,
    GlButton,
    GlFormInput,
    GlForm,
    GlAlert,
    ProjectDropdown,
    SourceBranchDropdown,
  },
  props: {
    initialBranchName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selectedProject: null,
      selectedSourceBranchName: null,
      branchName: this.initialBranchName,
      createBranchLoading: false,
      alertParams: {
        ...DEFAULT_ALERT_PARAMS,
      },
    };
  },
  computed: {
    selectedProjectId() {
      return this.selectedProject?.id;
    },
    showAlert() {
      return Boolean(this.alertParams?.message);
    },
    disableSubmitButton() {
      return !(this.selectedProject && this.selectedSourceBranchName && this.branchName);
    },
  },
  methods: {
    displayAlert({
      title,
      message,
      variant = DEFAULT_ALERT_VARIANT,
      primaryButtonLink,
      primaryButtonText,
    } = {}) {
      this.alertParams = {
        title,
        message,
        variant,
        primaryButtonLink,
        primaryButtonText,
      };
    },
    onAlertDismiss() {
      this.alertParams = {
        ...DEFAULT_ALERT_PARAMS,
      };
    },
    async onProjectSelect(project) {
      this.selectedProject = project;
      this.selectedSourceBranchName = null; // reset branch selection
    },
    onSourceBranchSelect(branchName) {
      this.selectedSourceBranchName = branchName;
    },
    onError({ title, message } = {}) {
      this.displayAlert({
        message,
        title,
      });
    },
    onSubmit() {
      this.createBranch();
    },
    async createBranch() {
      this.createBranchLoading = true;
      this.$apollo
        .mutate({
          mutation: createBranchMutation,
          variables: {
            name: this.branchName,
            ref: this.selectedSourceBranchName,
            projectPath: this.selectedProject.fullPath,
          },
        })
        .then(({ data }) => {
          const { errors } = data.createBranch;
          if (errors.length > 0) {
            this.onError({
              title: __('Failed to create branch.'),
              message: errors[0],
            });
            return;
          }

          this.displayAlert({
            title: __('New branch was successfully created.'),
            message: __('You can now close this window and return to Jira'),
            variant: 'success',
            primaryButtonLink: 'jira',
            primaryButtonText: __('Return to Jira'),
          });
        })
        .catch(() => {
          this.onError({
            message: __('Failed to create branch. Please try again.'),
          });
        })
        .finally(() => {
          this.createBranchLoading = false;
        });
    },
  },
  i18n: {
    pageTitle: __('New branch'),
    projectDropdownLabel: __('Project'),
    branchNameInputLabel: __('Branch name'),
    sourceBranchDropdownLabel: __('Source branch'),
    formSubmitButtonText: __('Create branch'),
  },
};
</script>

<template>
  <div>
    <div class="gl-border-1 gl-border-b-solid gl-border-gray-100 gl-mb-5 gl-mt-7">
      <h1 class="page-title">
        {{ $options.i18n.pageTitle }}
      </h1>
    </div>

    <gl-alert
      v-if="showAlert"
      class="gl-mb-5"
      :variant="alertParams.variant"
      :title="alertParams.title"
      :primary-button-link="alertParams.primaryButtonLink"
      :primary-button-text="alertParams.primaryButtonText"
      @dismiss="onAlertDismiss"
    >
      {{ alertParams.message }}
    </gl-alert>

    <gl-form @submit.prevent="onSubmit">
      <gl-form-group :label="$options.i18n.projectDropdownLabel" label-for="project-select">
        <project-dropdown
          id="project-select"
          :selected-project="selectedProject"
          @change="onProjectSelect"
          @error="onError"
        />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.branchNameInputLabel" label-for="branch-name-input">
        <gl-form-input id="branch-name-input" v-model="branchName" type="text" required />
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.sourceBranchDropdownLabel"
        label-for="source-branch-select"
      >
        <source-branch-dropdown
          id="source-branch-select"
          :selected-project="selectedProject"
          :selected-branch-name="selectedSourceBranchName"
          @change="onSourceBranchSelect"
          @error="onError"
        />
      </gl-form-group>

      <div class="form-actions">
        <gl-button
          :loading="createBranchLoading"
          type="submit"
          variant="confirm"
          :disabled="disableSubmitButton"
        >
          {{ $options.i18n.formSubmitButtonText }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
