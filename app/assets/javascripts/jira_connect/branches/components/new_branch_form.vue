<script>
import { GlFormGroup, GlButton, GlFormInput, GlForm, GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  CREATE_BRANCH_ERROR_GENERIC,
  CREATE_BRANCH_ERROR_WITH_CONTEXT,
  I18N_NEW_BRANCH_LABEL_DROPDOWN,
  I18N_NEW_BRANCH_LABEL_BRANCH,
  I18N_NEW_BRANCH_LABEL_SOURCE,
  I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT,
  I18N_NEW_BRANCH_PERMISSION_ALERT,
} from '../constants';
import createBranchMutation from '../graphql/mutations/create_branch.mutation.graphql';
import ProjectDropdown from './project_dropdown.vue';
import SourceBranchDropdown from './source_branch_dropdown.vue';

const DEFAULT_ALERT_VARIANT = 'danger';
const DEFAULT_ALERT_PARAMS = {
  title: '',
  message: '',
  variant: DEFAULT_ALERT_VARIANT,
  link: undefined,
  dismissible: true,
};

export default {
  name: 'JiraConnectNewBranch',
  components: {
    GlFormGroup,
    GlButton,
    GlFormInput,
    GlForm,
    GlAlert,
    GlSprintf,
    GlLink,
    ProjectDropdown,
    SourceBranchDropdown,
  },
  inject: {
    initialBranchName: {
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
      hasPermission: false,
    };
  },
  computed: {
    selectedProjectId() {
      return this.selectedProject?.id;
    },
    showAlert() {
      return Boolean(this.alertParams?.message);
    },
    isBranchNameValid() {
      return (this.branchName ?? '').trim().length > 0;
    },
    disableSubmitButton() {
      return !(this.selectedProject && this.selectedSourceBranchName && this.isBranchNameValid);
    },
  },
  methods: {
    displayAlert({
      title,
      message,
      variant = DEFAULT_ALERT_VARIANT,
      link,
      dismissible = true,
    } = {}) {
      this.alertParams = {
        title,
        message,
        variant,
        link,
        dismissible,
      };
    },
    setPermissionAlert() {
      this.displayAlert({
        message: I18N_NEW_BRANCH_PERMISSION_ALERT,
        variant: 'warning',
        link: helpPagePath('user/permissions', { anchor: 'project-members-permissions' }),
        dismissible: false,
      });
    },
    dismissAlert() {
      this.alertParams = {
        ...DEFAULT_ALERT_PARAMS,
      };
    },
    onProjectSelect(project) {
      this.selectedProject = project;
      this.selectedSourceBranchName = null; // reset branch selection
      this.hasPermission = this.selectedProject.userPermissions.pushCode;

      if (!this.hasPermission) {
        this.setPermissionAlert();
      } else {
        // clear alert if the user has permissions for the newly-selected project.
        this.dismissAlert();
      }
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

      try {
        const { data } = await this.$apollo.mutate({
          mutation: createBranchMutation,
          variables: {
            name: this.branchName,
            ref: this.selectedSourceBranchName,
            projectPath: this.selectedProject.fullPath,
          },
        });
        const { errors } = data.createBranch;
        if (errors.length > 0) {
          this.onError({
            title: CREATE_BRANCH_ERROR_WITH_CONTEXT,
            message: errors[0],
          });
        } else {
          this.$emit('success');
        }
      } catch (e) {
        this.onError({
          message: CREATE_BRANCH_ERROR_GENERIC,
        });
      }

      this.createBranchLoading = false;
    },
  },
  i18n: {
    I18N_NEW_BRANCH_LABEL_DROPDOWN,
    I18N_NEW_BRANCH_LABEL_BRANCH,
    I18N_NEW_BRANCH_LABEL_SOURCE,
    I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT,
  },
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <gl-alert
      v-if="showAlert"
      class="gl-mb-5"
      :variant="alertParams.variant"
      :title="alertParams.title"
      :dismissible="alertParams.dismissible"
      @dismiss="dismissAlert"
    >
      <gl-sprintf :message="alertParams.message">
        <template #link="{ content }">
          <gl-link :href="alertParams.link" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-form-group :label="$options.i18n.I18N_NEW_BRANCH_LABEL_DROPDOWN" label-for="project-select">
      <project-dropdown
        id="project-select"
        :selected-project="selectedProject"
        @change="onProjectSelect"
        @error="onError"
      />
    </gl-form-group>

    <template v-if="selectedProject && hasPermission">
      <gl-form-group
        :label="$options.i18n.I18N_NEW_BRANCH_LABEL_SOURCE"
        label-for="source-branch-select"
      >
        <source-branch-dropdown
          id="source-branch-select"
          :key="selectedProject.id"
          :selected-project="selectedProject"
          :selected-branch-name="selectedSourceBranchName"
          @change="onSourceBranchSelect"
          @error="onError"
        />
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.I18N_NEW_BRANCH_LABEL_BRANCH"
        label-for="branch-name-input"
        class="gl-max-w-62"
      >
        <gl-form-input id="branch-name-input" v-model="branchName" type="text" required />
      </gl-form-group>
    </template>

    <div class="form-actions">
      <gl-button
        :loading="createBranchLoading"
        type="submit"
        variant="confirm"
        :disabled="disableSubmitButton"
      >
        {{ $options.i18n.I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT }}
      </gl-button>
    </div>
  </gl-form>
</template>
