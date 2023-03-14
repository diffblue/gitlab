<script>
import { GlAlert, GlButton, GlLoadingIcon, GlKeysetPagination, GlTab, GlTabs } from '@gitlab/ui';
import produce from 'immer';
import {
  STATUS_ALL,
  STATUS_CLOSED,
  STATUS_OPEN,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import destroyIterationCadence from '../queries/destroy_cadence.mutation.graphql';
import groupQuery from '../queries/group_iteration_cadences_list.query.graphql';
import projectQuery from '../queries/project_iteration_cadences_list.query.graphql';
import IterationCadenceListItem from './iteration_cadence_list_item.vue';

export default {
  iterationCadencesHelpPagePath: helpPagePath('user/group/iterations/index.md', {
    anchor: 'iteration-cadences',
  }),
  i18n: {
    tabTitles: [s__('Iterations|Open'), s__('Iterations|Done'), s__('Iterations|All')],
  },
  components: {
    IterationCadenceListItem,
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlKeysetPagination,
    GlTab,
    GlTabs,
  },
  apollo: {
    workspace: {
      query() {
        return this.query;
      },
      variables() {
        return this.queryVariables;
      },
      error({ message }) {
        this.error = message || s__('Iterations|Error loading iteration cadences.');
      },
    },
  },
  inject: ['fullPath', 'cadencesListPath', 'canCreateCadence', 'namespaceType'],
  data() {
    return {
      workspace: {
        iterationCadences: {
          nodes: [],
          pageInfo: {
            hasNextPage: true,
            hasPreviousPage: false,
          },
        },
      },
      pagination: {},
      tabIndex: 0,
      error: '',
    };
  },
  computed: {
    query() {
      if (this.namespaceType === WORKSPACE_GROUP) {
        return groupQuery;
      }
      if (this.namespaceType === WORKSPACE_PROJECT) {
        return projectQuery;
      }
      throw new Error('Must provide a namespaceType');
    },
    queryVariables() {
      const vars = {
        fullPath: this.fullPath,
      };

      if (this.pagination.beforeCursor) {
        vars.beforeCursor = this.pagination.beforeCursor;
        vars.lastPageSize = DEFAULT_PAGE_SIZE;
      } else {
        vars.afterCursor = this.pagination.afterCursor;
        vars.firstPageSize = DEFAULT_PAGE_SIZE;
      }

      return vars;
    },
    cadences() {
      return this.workspace?.iterationCadences?.nodes || [];
    },
    pageInfo() {
      return this.workspace?.iterationCadences?.pageInfo || {};
    },
    loading() {
      return this.$apollo.queries.workspace.loading;
    },
    state() {
      switch (this.tabIndex) {
        case 0:
          return STATUS_OPEN;
        case 1:
          return STATUS_CLOSED;
        case 2:
          return STATUS_ALL;
        default:
          return STATUS_OPEN;
      }
    },
  },
  mounted() {
    if (this.$router.currentRoute.query.createdCadenceId) {
      this.$apollo.queries.workspace.refetch();
    }
  },
  methods: {
    nextPage() {
      this.pagination = {
        afterCursor: this.pageInfo.endCursor,
      };
    },
    previousPage() {
      this.pagination = {
        beforeCursor: this.pageInfo.startCursor,
      };
    },
    handleTabChange() {
      this.pagination = {};
    },
    deleteCadence(cadenceId) {
      this.$apollo
        .mutate({
          mutation: destroyIterationCadence,
          variables: {
            id: cadenceId,
          },
          update: (store, { data: { iterationCadenceDestroy } }) => {
            if (iterationCadenceDestroy.errors?.length) {
              throw iterationCadenceDestroy.errors[0];
            }

            const sourceData = store.readQuery({
              query: this.query,
              variables: this.queryVariables,
            });

            const data = produce(sourceData, (draftData) => {
              draftData.workspace.iterationCadences.nodes = draftData.workspace.iterationCadences.nodes.filter(
                ({ id }) => id !== cadenceId,
              );
            });

            store.writeQuery({
              query: this.query,
              variables: this.queryVariables,
              data,
            });
          },
        })
        .catch((err) => {
          this.error = err;
        });
    },
  },
};
</script>

<template>
  <gl-tabs v-model="tabIndex" @activate-tab="handleTabChange">
    <gl-tab v-for="tab in $options.i18n.tabTitles" :key="tab">
      <template #title>
        {{ tab }}
      </template>

      <gl-alert v-if="error" variant="danger" @dismiss="error = ''">
        {{ error }}
      </gl-alert>

      <gl-loading-icon v-if="loading" class="gl-my-5" size="lg" />

      <template v-else>
        <ul v-if="cadences.length" class="content-list">
          <iteration-cadence-list-item
            v-for="cadence in cadences"
            :key="cadence.id"
            :cadence-id="cadence.id"
            :duration-in-weeks="cadence.durationInWeeks"
            :automatic="cadence.automatic"
            :title="cadence.title"
            :iteration-state="state"
            :show-state-badge="tabIndex === 2"
            data-qa-selector="cadence_list_item_content"
            @delete-cadence="deleteCadence"
          />
        </ul>
        <p v-else class="nothing-here-block">
          {{ s__('Iterations|No iteration cadences to show.') }}
        </p>
        <div
          v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage"
          class="gl-display-flex gl-justify-content-center gl-mt-3"
        >
          <gl-keyset-pagination
            :has-next-page="pageInfo.hasNextPage"
            :has-previous-page="pageInfo.hasPreviousPage"
            @prev="previousPage"
            @next="nextPage"
          />
        </div>
      </template>
    </gl-tab>
    <template v-if="canCreateCadence" #tabs-end>
      <li class="gl-ml-auto gl-display-flex gl-align-items-center">
        <gl-button
          variant="confirm"
          data-qa-selector="create_new_cadence_button"
          :to="{
            name: 'new',
          }"
        >
          {{ s__('Iterations|New iteration cadence') }}
        </gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
