<script>
import { GlTableLite, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { WORKSPACE_STATES } from '../../constants';
import WorkspaceStateIndicator from '../common/workspace_state_indicator.vue';
import UpdateWorkspaceMutation from '../common/update_workspace_mutation.vue';
import WorkspaceActions from '../common/workspace_actions.vue';

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
};

export default {
  components: {
    GlTableLite,
    GlLink,
    WorkspaceStateIndicator,
    WorkspaceActions,
    UpdateWorkspaceMutation,
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
  fields: [
    {
      key: 'status',
      /*
       * The status and action columns in this table
       * do not have a label in the table header. We
       * use this zero-width unicode character because
       * using an empty string breaks the table alignment
       * in mobile views.
       */
      label: '\u200b',
      thClass: 'gl-w-5p',
    },
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
      label: '\u200b',
      thClass: 'gl-w-20p',
    },
  ],
  i18n,
  WORKSPACE_STATES,
};
</script>
<template>
  <update-workspace-mutation
    @updateFailed="$emit('updateFailed', $event)"
    @updateSucceed="$emit('updateSucceed')"
  >
    <template #default="{ update }">
      <gl-table-lite
        :items="sortedWorkspaces"
        stacked="sm"
        :fields="$options.fields"
        :tbody-tr-attr="(item) => ({ 'data-testid': item.name })"
      >
        <template #cell(status)="{ item }">
          <workspace-state-indicator
            :workspace-state="item.actualState"
            class="gl-mr-5"
            :data-qa-selector="`${item.name}_actual_state`"
          />
        </template>
        <template #cell(name)="{ item }">
          <div class="gl-display-flex gl-flex-direction-column">
            <span class="gl-text-gray-500 gl-font-sm gl-pb-1"> {{ item.projectName }} </span>
            <span class="gl-text-black-normal"> {{ item.name }} </span>
          </div>
        </template>
        <template #cell(preview)="{ item }">
          <gl-link
            v-if="item.actualState === $options.WORKSPACE_STATES.running"
            :href="item.url"
            class="workspace-preview-link"
            target="_blank"
            data-testid="`${item.name}_link`"
            >{{ item.url }}</gl-link
          >
        </template>
        <template #cell(actions)="{ item }">
          <workspace-actions
            :actual-state="item.actualState"
            :desired-state="item.desiredState"
            :data-qa-selector="`${item.name}_action`"
            @click="update(item.id, { desiredState: $event })"
          />
        </template>
      </gl-table-lite>
    </template>
  </update-workspace-mutation>
</template>
