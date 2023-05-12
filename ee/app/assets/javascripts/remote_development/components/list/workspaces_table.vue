<script>
import { GlTableLite, GlLink } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import { __, s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORKSPACE } from '~/graphql_shared/constants';
import { WORKSPACE_STATES } from '../../constants';
import workspaceUpdateMutation from '../../graphql/mutations/workspace_update.mutation.graphql';
import WorkspaceStateIndicator from './workspace_state_indicator.vue';
import WorkspaceActions from './workspace_actions.vue';

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
  tableColumnHeaders: {
    name: __('Name'),
    preview: __('Preview'),
  },
  updateWorkspaceFailedMessage: s__('Workspaces|Failed to update workspace'),
};

export default {
  components: {
    GlTableLite,
    GlLink,
    WorkspaceStateIndicator,
    WorkspaceActions,
  },
  props: {
    workspaces: {
      type: Array,
      required: true,
    },
  },
  computed: {
    sortedWorkspaces() {
      return [...this.workspaces].sort(sortWorkspacesByTerminatedState);
    },
  },
  methods: {
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
            this.$emit('updateFailed', { error });
          }
        })
        .catch((e) => {
          logError(e);
          this.$emit('updateFailed', { error: i18n.updateWorkspaceFailedMessage });
        });
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
  i18n,
  WORKSPACE_STATES,
};
</script>
<template>
  <gl-table-lite :items="sortedWorkspaces" :fields="$options.fields">
    <template #cell(name)="{ item }">
      <div class="gl-display-flex gl-align-items-center">
        <workspace-state-indicator
          :workspace-state="item.actualState"
          class="gl-mr-5"
          :data-qa-selector="`${item.name}_actual_state`"
        />
        <div class="gl-display-flex gl-flex-direction-column">
          <span class="gl-text-gray-500 gl-font-sm gl-pb-1"> {{ item.projectName }} </span>
          <span class="gl-text-black-normal"> {{ item.name }} </span>
        </div>
      </div>
    </template>
    <template #cell(preview)="{ item }">
      <gl-link
        v-if="item.actualState === $options.WORKSPACE_STATES.running"
        :href="item.url"
        class="workspace-preview-link"
        target="_blank"
        >{{ item.url }}</gl-link
      >
    </template>
    <template #cell(actions)="{ item }">
      <workspace-actions
        :actual-state="item.actualState"
        :desired-state="item.desiredState"
        :data-qa-selector="`${item.name}_action`"
        @click="updateWorkspace(item.id, $event)"
      />
    </template>
  </gl-table-lite>
</template>
