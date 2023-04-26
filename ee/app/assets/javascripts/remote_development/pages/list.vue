<script>
import { GlAlert, GlButton, GlLink, GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORKSPACE } from '~/graphql_shared/constants';
import {
  WORKSPACE_STATES,
  ROUTES,
  WORKSPACE_DESIRED_STATES,
  WORKSPACES_LIST_POLL_INTERVAL,
} from '../constants';
import userWorkspacesListQuery from '../graphql/queries/user_workspaces_list.query.graphql';
import workspaceUpdateMutation from '../graphql/mutations/workspace_update.mutation.graphql';
import WorkspaceEmptyState from '../components/list/empty_state.vue';
import WorkspaceStateIndicator from '../components/list/workspace_state_indicator.vue';
import TerminateWorkspaceButton from '../components/list/terminate_workspace_button.vue';
import StartWorkspaceButton from '../components/list/start_workspace_button.vue';
import StopWorkspaceButton from '../components/list/stop_workspace_button.vue';
import RestartWorkspaceButton from '../components/list/restart_workspace_button.vue';

export const i18n = {
  updateWorkspaceFailedMessage: s__('Workspaces|Failed to update workspace'),
  tableColumnHeaders: {
    name: __('Name'),
    preview: __('Preview'),
  },
  heading: s__('Workspaces|Workspaces'),
  newWorkspaceButton: s__('Workspaces|New workspace'),
};

export default {
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlSkeletonLoader,
    GlTableLite,
    WorkspaceEmptyState,
    WorkspaceStateIndicator,
    TerminateWorkspaceButton,
    StartWorkspaceButton,
    StopWorkspaceButton,
    RestartWorkspaceButton,
  },
  apollo: {
    workspaces: {
      query: userWorkspacesListQuery,
      pollInterval: WORKSPACES_LIST_POLL_INTERVAL,
      update(data) {
        return data.currentUser.workspaces.nodes;
      },
      error(err) {
        logError(err);
        this.error = __(
          'Unable to load current Workspaces. Please try again or contact an administrator.',
        );
      },
    },
  },
  fields: [
    {
      key: 'name',
      label: i18n.tableColumnHeaders.name,
      thClass: 'gl-w-25p',
    },
    {
      key: 'preview',
      label: i18n.tableColumnHeaders.preview,
      thClass: 'gl-w-30p',
    },
    {
      key: 'actions',
      label: '',
      thClass: 'gl-w-20p',
    },
  ],
  data() {
    return {
      workspaces: [],
      error: '',
    };
  },
  computed: {
    isEmpty() {
      return !this.workspaces.length && !this.isLoading;
    },
    isLoading() {
      return this.$apollo.loading;
    },
    filteredWorkspaces() {
      return this.workspaces?.filter(
        (workspace) => workspace.actualState !== WORKSPACE_STATES.terminated,
      );
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    terminateWorkspace(workspace) {
      this.updateWorkspace({ id: workspace.id, desiredState: WORKSPACE_DESIRED_STATES.terminated });
    },
    startWorkspace(workspace) {
      this.updateWorkspace({ id: workspace.id, desiredState: WORKSPACE_DESIRED_STATES.running });
    },
    stopWorkspace(workspace) {
      this.updateWorkspace({ id: workspace.id, desiredState: WORKSPACE_DESIRED_STATES.stopped });
    },
    restartWorkspace(workspace) {
      this.updateWorkspace({ id: workspace.id, desiredState: WORKSPACE_DESIRED_STATES.restarting });
    },
    updateWorkspace({ id, desiredState }) {
      return this.$apollo
        .mutate({
          mutation: workspaceUpdateMutation,
          variables: {
            input: {
              id: convertToGraphQLId(TYPE_WORKSPACE, id),
              desiredState,
            },
          },
        })
        .then(({ data }) => {
          const {
            errors: [error],
          } = data.workspaceUpdate;

          if (error) {
            this.error = error;
          }
        })
        .catch((e) => {
          logError(e);
          this.error = i18n.updateWorkspaceFailedMessage;
        });
    },
  },
  i18n,
  WORKSPACE_STATES,
  ROUTES,
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="clearError">
      {{ error }}
    </gl-alert>

    <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
      <h2>{{ $options.i18n.heading }}</h2>
      <gl-button variant="confirm" :to="$options.ROUTES.create">{{
        $options.i18n.newWorkspaceButton
      }}</gl-button>
    </div>

    <workspace-empty-state v-if="isEmpty" />

    <template v-else>
      <div v-if="isLoading" class="gl-p-5 gl-display-flex gl-justify-content-left">
        <gl-skeleton-loader :lines="4" :equal-width-lines="true" :width="600" />
      </div>

      <gl-table-lite v-else :items="filteredWorkspaces" :fields="$options.fields">
        <template #cell(name)="{ item }">
          <div class="gl-display-flex gl-text-gray-500 gl-align-items-center">
            <workspace-state-indicator :workspace-state="item.actualState" class="gl-mr-5" />
            <div class="gl-display-flex gl-flex-direction-column">
              <span> {{ item.project.nameWithNamespace }} </span>
              <span> {{ item.name }} </span>
            </div>
          </div>
        </template>
        <template #cell(preview)="{ item }">
          <gl-link
            v-if="item.actualState === $options.WORKSPACE_STATES.running"
            :href="item.url"
            target="_blank"
            >{{ item.url }}</gl-link
          >
        </template>
        <template #cell(actions)="{ item }">
          <span class="gl-display-flex gl-justify-content-end">
            <restart-workspace-button
              class="gl-mr-2"
              :actual-state="item.actualState"
              :desired-state="item.desiredState"
              @click="restartWorkspace(item)"
            />
            <start-workspace-button
              class="gl-mr-2"
              :actual-state="item.actualState"
              :desired-state="item.desiredState"
              @click="startWorkspace(item)"
            />
            <stop-workspace-button
              class="gl-mr-2"
              :actual-state="item.actualState"
              :desired-state="item.desiredState"
              @click="stopWorkspace(item)"
            />
            <terminate-workspace-button
              :actual-state="item.actualState"
              :desired-state="item.desiredState"
              @click="terminateWorkspace(item)"
            />
          </span>
        </template>
      </gl-table-lite>
    </template>
  </div>
</template>
