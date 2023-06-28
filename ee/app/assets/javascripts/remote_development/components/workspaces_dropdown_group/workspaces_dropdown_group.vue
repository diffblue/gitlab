<script>
import { GlAlert, GlDisclosureDropdownGroup, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { logError } from '~/lib/logger';
import { helpPagePath } from '~/helpers/help_page_helper';
import userWorkspacesListQuery from '../../graphql/queries/user_workspaces_list.query.graphql';
import {
  WORKSPACES_LIST_POLL_INTERVAL,
  WORKSPACES_DROPDOWN_GROUP_PAGE_SIZE,
  WORKSPACE_STATES,
} from '../../constants';
import UpdateWorkspaceMutation from '../common/update_workspace_mutation.vue';
import WorkspaceDropdownItem from './workspace_dropdown_item.vue';

export const i18n = {
  workspacesGroupLabel: s__('Workspaces|Your workspaces'),
  newWorkspaceButton: s__('Workspaces|New workspace'),
  noWorkspacesMessage: s__(
    'Workspaces|A workspace is a virtual sandbox environment for your code in GitLab. You can create a workspace for a public project.',
  ),
  loadingWorkspacesFailedMessage: s__('Workspaces|Could not load workspaces'),
};

const workspacesHelpPath = helpPagePath('user/workspace/index.md');

export default {
  components: {
    GlAlert,
    GlDisclosureDropdownGroup,
    GlLoadingIcon,
    WorkspaceDropdownItem,
    UpdateWorkspaceMutation,
  },
  inject: ['projectId'],
  apollo: {
    workspaces: {
      query: userWorkspacesListQuery,
      pollInterval: WORKSPACES_LIST_POLL_INTERVAL,
      variables() {
        return {
          first: WORKSPACES_DROPDOWN_GROUP_PAGE_SIZE,
          after: null,
          before: null,
          includeActualStates: [
            WORKSPACE_STATES.creationRequested,
            WORKSPACE_STATES.starting,
            WORKSPACE_STATES.running,
            WORKSPACE_STATES.stopping,
            WORKSPACE_STATES.stopped,
            WORKSPACE_STATES.terminating,
            WORKSPACE_STATES.failed,
            WORKSPACE_STATES.error,
            WORKSPACE_STATES.unknown,
          ],
          projectIds: [this.projectId],
        };
      },
      update(data) {
        this.loadingWorkspacesFailed = false;

        return data.currentUser.workspaces?.nodes || [];
      },
      error(err) {
        this.loadingWorkspacesFailed = true;
        logError(err);
      },
    },
  },
  data() {
    return {
      workspaces: [],
      loadingWorkspacesFailed: false,
      updateWorkspaceErrorMessage: null,
    };
  },
  computed: {
    hasWorkspaces() {
      return this.workspaces.length > 0;
    },
    isLoading() {
      return this.$apollo.queries.workspaces.loading;
    },
  },
  methods: {
    displayUpdateFailedAlert({ error }) {
      this.updateWorkspaceErrorMessage = error;
    },
    hideUpdateFailedAlert() {
      this.updateWorkspaceErrorMessage = null;
    },
  },
  i18n,
  workspacesHelpPath,
};
</script>
<template>
  <update-workspace-mutation
    @updateSucceed="hideUpdateFailedAlert"
    @updateFailed="displayUpdateFailedAlert"
  >
    <template #default="{ update }">
      <gl-disclosure-dropdown-group class="gl-max-w-48 gl-py-2">
        <template #group-label>
          <span class="gl-font-sm">{{ $options.i18n.workspacesGroupLabel }}</span>
        </template>
        <gl-loading-icon v-if="isLoading" />
        <template v-else>
          <gl-alert
            v-if="loadingWorkspacesFailed"
            variant="danger"
            :show-icon="false"
            :dismissible="false"
          >
            {{ $options.i18n.loadingWorkspacesFailedMessage }}
          </gl-alert>
          <template v-else-if="hasWorkspaces">
            <gl-alert
              v-if="updateWorkspaceErrorMessage"
              data-testid="update-workspace-error-alert"
              variant="danger"
              :show-icon="false"
              :dismissible="false"
            >
              {{ updateWorkspaceErrorMessage }}
            </gl-alert>
            <workspace-dropdown-item
              v-for="workspace in workspaces"
              :key="workspace.id"
              :workspace="workspace"
              @updateWorkspace="update(workspace.id, $event)"
            />
          </template>
          <div v-else class="gl-px-4 gl-py-2 gl-font-sm" data-testid="no-workspaces-message">
            {{ $options.i18n.noWorkspacesMessage }}
          </div>
        </template>
      </gl-disclosure-dropdown-group>
    </template>
  </update-workspace-mutation>
</template>
