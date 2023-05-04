<script>
import { GlAlert, GlButton, GlLink, GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORKSPACE } from '~/graphql_shared/constants';
import { WORKSPACE_STATES, ROUTES, WORKSPACES_LIST_POLL_INTERVAL } from '../constants';
import userWorkspacesListQuery from '../graphql/queries/user_workspaces_list.query.graphql';
import userWorkspacesProjectsNamesQuery from '../graphql/queries/user_workspaces_projects_names.query.graphql';
import workspaceUpdateMutation from '../graphql/mutations/workspace_update.mutation.graphql';
import WorkspaceEmptyState from '../components/list/empty_state.vue';
import WorkspaceStateIndicator from '../components/list/workspace_state_indicator.vue';
import WorkspaceActions from '../components/list/workspace_actions.vue';

const isTerminated = (w) => w.actualState === WORKSPACE_STATES.terminated;

// Moves terminated workspaces to the end of the list
const sortWorkspacesByTerminatedState = (workspaceA, workspaceB) => {
  const isWorkspaceATerminated = isTerminated(workspaceA);
  const isWorkspaceBTerminated = isTerminated(workspaceB);

  if (isWorkspaceATerminated === isWorkspaceBTerminated) {
    return 0; // Preserve default order when neither workspace is terminated, or both workspaces are terminated.
  } else if (isWorkspaceATerminated) {
    return 1; // Place workspaceA after workspaceB since it is terminated.
  }

  return -1; // Place workspaceA before workspaceB since it is not terminated.
};

export const i18n = {
  updateWorkspaceFailedMessage: s__('Workspaces|Failed to update workspace'),
  tableColumnHeaders: {
    name: __('Name'),
    preview: __('Preview'),
  },
  heading: s__('Workspaces|Workspaces'),
  newWorkspaceButton: s__('Workspaces|New workspace'),
  loadingWorkspacesFailed: s__(
    'Workspaces|Unable to load current Workspaces. Please try again or contact an administrator.',
  ),
};

export default {
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlSkeletonLoader,
    GlTableLite,
    WorkspaceActions,
    WorkspaceEmptyState,
    WorkspaceStateIndicator,
  },
  apollo: {
    workspaces: {
      query: userWorkspacesListQuery,
      pollInterval: WORKSPACES_LIST_POLL_INTERVAL,
      update(data) {
        return data.currentUser.workspaces?.nodes || [];
      },
      error(err) {
        logError(err);
      },
      async result({ data, error }) {
        if (error) {
          this.error = i18n.loadingWorkspacesFailed;
          return;
        }
        const workspaces = data.currentUser.workspaces.nodes;
        const result = await this.fetchProjectNames(workspaces);

        if (result.error) {
          this.error = i18n.loadingWorkspacesFailed;
          return;
        }

        this.workspaces = workspaces.map((workspace) => ({
          ...workspace,
          projectName: result.projectIdToNameMap[workspace.projectId] || workspace.projectId,
        }));
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
      return !this.sortedWorkspaces.length && !this.isLoading;
    },
    isLoading() {
      return this.$apollo.loading;
    },
    sortedWorkspaces() {
      return [...this.workspaces].sort(sortWorkspacesByTerminatedState);
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    async fetchProjectNames(workspaces) {
      const projectIds = workspaces.map(({ projectId }) => projectId);

      try {
        const {
          data: { projects },
          error,
        } = await this.$apollo.query({
          query: userWorkspacesProjectsNamesQuery,
          variables: { ids: projectIds },
        });

        if (error) {
          return { error };
        }

        return {
          projectIdToNameMap: projects.nodes.reduce(
            (map, project) => ({
              ...map,
              [project.id]: project.nameWithNamespace,
            }),
            {},
          ),
        };
      } catch (error) {
        return { error };
      }
    },
    updateWorkspace(id, desiredState) {
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

      <gl-table-lite v-else :items="sortedWorkspaces" :fields="$options.fields">
        <template #cell(name)="{ item }">
          <div class="gl-display-flex gl-text-gray-500 gl-align-items-center">
            <workspace-state-indicator :workspace-state="item.actualState" class="gl-mr-5" />
            <div class="gl-display-flex gl-flex-direction-column">
              <span> {{ item.projectName }} </span>
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
          <workspace-actions
            :actual-state="item.actualState"
            :desired-state="item.desiredState"
            @click="updateWorkspace(item.id, $event)"
          />
        </template>
      </gl-table-lite>
    </template>
  </div>
</template>
