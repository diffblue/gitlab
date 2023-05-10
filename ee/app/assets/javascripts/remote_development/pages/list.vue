<script>
import { GlAlert, GlBadge, GlButton, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { WORKSPACES_LIST_PAGE_SIZE, ROUTES, WORKSPACES_LIST_POLL_INTERVAL } from '../constants';
import userWorkspacesListQuery from '../graphql/queries/user_workspaces_list.query.graphql';
import userWorkspacesProjectsNamesQuery from '../graphql/queries/user_workspaces_projects_names.query.graphql';
import WorkspaceEmptyState from '../components/list/empty_state.vue';
import WorkspacesTable from '../components/list/workspaces_table.vue';
import WorkspacesListPagination from '../components/list/workspaces_list_pagination.vue';
import { populateWorkspacesWithProjectNames } from '../services/utils';

export const i18n = {
  updateWorkspaceFailedMessage: s__('Workspaces|Failed to update workspace'),
  betaBadge: __('Beta'),
  learnMoreHelpLink: __('Learn more'),
  heading: s__('Workspaces|Workspaces'),
  newWorkspaceButton: s__('Workspaces|New workspace'),
  loadingWorkspacesFailed: s__(
    'Workspaces|Unable to load current Workspaces. Please try again or contact an administrator.',
  ),
};

const workspacesHelpPath = helpPagePath('user/workspace/index.md');

export default {
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlBadge,
    GlSkeletonLoader,
    WorkspaceEmptyState,
    WorkspacesListPagination,
    WorkspacesTable,
  },
  apollo: {
    workspaces: {
      query: userWorkspacesListQuery,
      pollInterval: WORKSPACES_LIST_POLL_INTERVAL,
      variables() {
        return {
          ...this.paginationVariables,
        };
      },
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
          this.workspaces = [];
          logError(result.error);
          return;
        }

        this.workspaces = populateWorkspacesWithProjectNames(workspaces, result.projects);
        this.pageInfo = data.currentUser.workspaces.pageInfo;
      },
    },
  },
  data() {
    return {
      workspaces: [],
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: null,
        endCursor: null,
      },
      paginationVariables: {
        first: WORKSPACES_LIST_PAGE_SIZE,
        after: null,
        before: null,
      },
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
        } = await this.$apollo.query({
          query: userWorkspacesProjectsNamesQuery,
          variables: { ids: projectIds },
        });

        return {
          projects: projects.nodes,
        };
      } catch (error) {
        return { error };
      }
    },
    onUpdateFailed({ error }) {
      this.error = error;
    },
    onPaginationInput(paginationVariables) {
      this.paginationVariables = paginationVariables;
    },
  },
  i18n,
  ROUTES,
  workspacesHelpPath,
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="clearError">
      {{ error }}
    </gl-alert>
    <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
      <div class="gl-display-flex gl-align-items-center">
        <h2>{{ $options.i18n.heading }}</h2>
        <gl-badge class="gl-mt-4 gl-ml-3" variant="info">{{ $options.i18n.betaBadge }}</gl-badge>
      </div>
      <div class="gl-display-flex gl-align-items-center">
        <gl-link class="gl-mr-5 workspace-preview-link" :href="$options.workspacesHelpPath">{{
          $options.i18n.learnMoreHelpLink
        }}</gl-link>
        <gl-button variant="confirm" :to="$options.ROUTES.create">{{
          $options.i18n.newWorkspaceButton
        }}</gl-button>
      </div>
    </div>
    <workspace-empty-state v-if="isEmpty" />
    <template v-else>
      <div v-if="isLoading" class="gl-p-5 gl-display-flex gl-justify-content-left">
        <gl-skeleton-loader :lines="4" :equal-width-lines="true" :width="600" />
      </div>
      <div v-else>
        <workspaces-table :workspaces="workspaces" @updateFailed="onUpdateFailed" />
        <workspaces-list-pagination :page-info="pageInfo" @input="onPaginationInput" />
      </div>
    </template>
  </div>
</template>
