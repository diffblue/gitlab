<script>
import { GlAlert, GlButton, GlLink, GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { logError } from '~/lib/logger';
import { s__, __ } from '~/locale';
import { WORKSPACE_STATES, ROUTES } from '../constants';
import userWorkspacesListQuery from '../graphql/queries/user_workspaces_list.query.graphql';
import WorkspaceEmptyState from '../components/list/empty_state.vue';
import WorkspaceStateIndicator from '../components/list/workspace_state_indicator.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlSkeletonLoader,
    GlTableLite,
    WorkspaceEmptyState,
    WorkspaceStateIndicator,
  },
  inject: ['currentUsername'],
  apollo: {
    workspaces: {
      query: userWorkspacesListQuery,
      variables() {
        return {
          username: this.currentUsername,
        };
      },
      update(data) {
        return data.user.workspaces.nodes;
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
      label: __('Name'),
      thClass: 'gl-w-25p',
    },
    {
      key: 'preview',
      label: __('Preview'),
      thClass: 'gl-w-30p',
    },
    {
      key: 'actions',
      label: '',
      thClass: 'gl-w-10p',
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
    deleteWorkspace: () => {
      // TDOD: implement deleteWorkspace
    },
    formatDate(lastUsed) {
      return getTimeago().format(lastUsed);
    },
  },
  i18n: {
    heading: s__('Workspaces|Workspaces'),
    newWorkspaceButton: s__('Workspaces|New workspace'),
  },
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
          <gl-button icon="remove" @click="deleteWorkspace(item)" />
        </template>
      </gl-table-lite>
    </template>
  </div>
</template>
