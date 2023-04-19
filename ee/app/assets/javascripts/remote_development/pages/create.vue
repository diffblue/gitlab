<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { logError } from '~/lib/logger';
import { helpPagePath } from '~/helpers/help_page_helper';
import SearchProjectsListbox from '../components/create/search_projects_listbox.vue';
import GetProjectDetailsQuery from '../components/create/get_project_details_query.vue';
import workspaceCreateMutation from '../graphql/mutations/workspace_create.mutation.graphql';
import { DEFAULT_EDITOR } from '../constants';

export const i18n = {
  title: s__('Workspaces|New workspace'),
  subtitle: s__(
    'Workspaces|A workspace is a virtual sandbox environment for your code in GitLab. You can create a workspace on its own or as part of a project.',
  ),
  form: {
    devfileProject: s__('Workspaces|Select project'),
    agentId: s__('Workspaces|Select cluster agent'),
    editor: s__('Workspaces|Select default editor'),
    help: {
      devfileProjectHelp: s__('Workspaces|You can create a workspace for Premium projects only.'),
    },
  },
  alerts: {
    noAgents: {
      title: s__("Workspaces|You can't create a workspace for this project"),
      content: s__(
        "Workspaces|To create a workspace for this project, an administrator must configure an agent for the project's group.",
      ),
    },
    noDevFile: {
      title: s__("Workspaces|This project doesn't have a devfile"),
      content: s__(
        'Workspaces|A devfile is a configuration file for your workspace. Without a devfile, a default workspace is created for this project. You can change that workspace at any time.',
      ),
    },
  },
  submitButton: {
    create: s__('Workspaces|Create workspace'),
  },
  cancelButton: s__('Workspaces|Cancel'),
  createWorkspaceFailedMessage: s__('Workspaces|Failed to create workspace'),
  fetchProjectDetailsFailedMessage: s__(
    'Workspaces|Could not retrieve cluster agents for this project',
  ),
};

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormSelect,
    SearchProjectsListbox,
    GetProjectDetailsQuery,
  },
  data() {
    return {
      selectedProject: null,
      selectedAgent: null,
      isCreatingWorkspace: false,
      clusterAgents: [],
      hasDevFile: true,
      groupPath: null,
      projectId: null,
      projectDetailsLoaded: false,
    };
  },
  computed: {
    emptyAgents() {
      return this.clusterAgents.length === 0;
    },
    displayClusterAgentsAlert() {
      return this.projectDetailsLoaded && this.emptyAgents;
    },
    displayNoDevFileAlert() {
      return this.projectDetailsLoaded && !this.displayClusterAgentsAlert && !this.hasDevFile;
    },
    saveWorkspaceEnabled() {
      return this.selectedProject && this.selectedAgent;
    },
    workspacesHelpPath() {
      return helpPagePath('user/project/remote_development/index', { anchor: 'workspace' });
    },
    selectedProjectFullPath() {
      return this.selectedProject?.fullPath;
    },
  },
  watch: {
    selectedProject() {
      this.clusterAgents = [];
      this.selectedAgent = null;
      this.projectDetailsLoaded = false;
    },
  },
  methods: {
    onProjectDetailsResult({ hasDevFile, clusterAgents, groupPath, id }) {
      this.projectDetailsLoaded = true;
      this.hasDevFile = hasDevFile;
      this.clusterAgents = clusterAgents;
      this.groupPath = groupPath;
      this.projectId = id;
    },
    onProjectDetailsError() {
      createAlert({ message: i18n.fetchProjectDetailsFailedMessage });
    },
    async createWorkspace() {
      try {
        this.isCreatingWorkspace = true;

        const { data } = await this.$apollo.mutate({
          mutation: workspaceCreateMutation,
          variables: {
            input: {
              projectId: this.projectId,
              groupPath: this.groupPath,
              clusterAgentId: this.selectedAgent,
              editor: DEFAULT_EDITOR,
            },
          },
        });

        const { errors, workspace } = data.workspaceCreate;

        if (errors.length > 0) {
          createAlert({ message: errors[0] });
          return;
        }

        visitUrl(workspace.url);
      } catch (error) {
        logError(error);
        createAlert({ message: i18n.createWorkspaceFailedMessage });
      } finally {
        this.isCreatingWorkspace = false;
      }
    },
  },
  i18n,
};
</script>
<template>
  <div class="gl-display-flex gl-sm-flex-direction-column">
    <div class="gl-flex-basis-third gl-mr-5">
      <h2 ref="pageTitle" class="page-title gl-font-size-h-display">
        {{ $options.i18n.title }}
      </h2>
      <p>
        {{ $options.i18n.subtitle }}
      </p>
    </div>
    <get-project-details-query
      :project-full-path="selectedProjectFullPath"
      @result="onProjectDetailsResult"
      @error="onProjectDetailsError"
    />
    <gl-form class="gl-mt-6 gl-flex-basis-two-thirds" @submit.prevent="createWorkspace">
      <gl-form-group
        :label="$options.i18n.form.devfileProject"
        :label-description="$options.i18n.form.help.devfileProjectHelp"
        label-for="workspace-devfile-project-id"
      >
        <search-projects-listbox v-model="selectedProject" />
        <gl-alert
          v-if="displayClusterAgentsAlert"
          data-testid="no-agents-alert"
          class="gl-mt-3"
          :title="$options.i18n.alerts.noAgents.title"
          variant="danger"
          :dismissible="false"
        >
          {{ $options.i18n.alerts.noAgents.content }}
        </gl-alert>
        <gl-alert
          v-if="displayNoDevFileAlert"
          data-testid="no-dev-file-alert"
          class="gl-mt-3"
          :title="$options.i18n.alerts.noDevFile.title"
          variant="info"
          :dismissible="false"
        >
          {{ $options.i18n.alerts.noDevFile.content }}
        </gl-alert>
      </gl-form-group>
      <gl-form-group
        v-if="clusterAgents.length"
        :label="$options.i18n.form.agentId"
        label-for="workspace-cluster-agent-id"
        data-testid="workspace-cluster-agent-form-group"
      >
        <gl-form-select
          id="workspace-cluster-agent-id"
          v-model="selectedAgent"
          :options="clusterAgents"
          required
          class="gl-max-w-full"
          autocomplete="off"
          data-qa-selector="workspace_cluster_agent_id_field"
        />
      </gl-form-group>
      <div>
        <gl-button
          :loading="isCreatingWorkspace"
          :disabled="!saveWorkspaceEnabled"
          type="submit"
          data-testid="create-workspace"
          variant="confirm"
          data-qa-selector="save_workspace_button"
        >
          {{ $options.i18n.submitButton.create }}
        </gl-button>
        <gl-button class="gl-ml-3" data-testid="cancel-workspace" to="root">
          {{ $options.i18n.cancelButton }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
