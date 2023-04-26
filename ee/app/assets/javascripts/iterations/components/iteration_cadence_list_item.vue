<script>
import {
  GlAlert,
  GlButton,
  GlCollapse,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
  GlInfiniteScroll,
  GlModal,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_CLOSED, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import { __, s__ } from '~/locale';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { getIterationPeriod } from '../utils';
import { CADENCE_AND_DUE_DATE_DESC } from '../constants';
import groupQuery from '../queries/group_iterations_in_cadence.query.graphql';
import projectQuery from '../queries/project_iterations_in_cadence.query.graphql';
import TimeboxStatusBadge from './timebox_status_badge.vue';

const i18n = Object.freeze({
  noResults: {
    opened: s__('Iterations|No open iterations.'),
    closed: s__('Iterations|No closed iterations.'),
    all: s__('Iterations|No iterations in cadence.'),
  },
  addIteration: s__('Iterations|Add iteration'),
  error: __('Error loading iterations'),

  deleteCadence: s__('Iterations|Delete cadence'),
  modalTitle: s__('Iterations|Delete iteration cadence?'),
  modalText: s__(
    'Iterations|This will delete the cadence as well as all of the iterations within it.',
  ),
  modalConfirm: s__('Iterations|Delete cadence'),
  modalCancel: __('Cancel'),
});

export default {
  i18n,
  components: {
    GlAlert,
    GlButton,
    GlCollapse,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlInfiniteScroll,
    GlModal,
    GlSkeletonLoader,
    TimeboxStatusBadge,
  },
  apollo: {
    workspace: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      skip() {
        return !this.expanded;
      },
      query() {
        return this.query;
      },
      variables() {
        return this.queryVariables;
      },
      error() {
        this.error = i18n.error;
      },
    },
  },
  inject: ['fullPath', 'canEditCadence', 'canCreateIteration', 'namespaceType'],
  props: {
    title: {
      type: String,
      required: true,
    },
    automatic: {
      type: Boolean,
      required: false,
      default: false,
    },
    durationInWeeks: {
      type: Number,
      required: false,
      default: null,
    },
    cadenceId: {
      type: String,
      required: true,
    },
    iterationState: {
      type: String,
      required: true,
    },
    showStateBadge: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      i18n,
      expanded: false,
      // query response
      workspace: {
        iterations: {
          nodes: [],
          pageInfo: {
            hasNextPage: true,
          },
        },
      },
      afterCursor: null,
      showMoreEnabled: true,
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
      return {
        fullPath: this.fullPath,
        iterationCadenceId: this.cadenceId,
        firstPageSize: DEFAULT_PAGE_SIZE,
        state: this.iterationState,
        sort: this.iterationSortOrder,
      };
    },
    pageInfo() {
      return this.workspace.iterations?.pageInfo || {};
    },
    hasNextPage() {
      return this.pageInfo.hasNextPage;
    },
    iterations() {
      return this.workspace?.iterations?.nodes || [];
    },
    loading() {
      return this.$apollo.queries.workspace.loading;
    },
    editCadence() {
      return {
        name: 'edit',
        params: {
          cadenceId: getIdFromGraphQLId(this.cadenceId),
        },
      };
    },
    newIteration() {
      return {
        name: 'newIteration',
        params: {
          cadenceId: getIdFromGraphQLId(this.cadenceId),
        },
      };
    },
    showAddIteration() {
      return !this.automatic && this.canCreateIteration;
    },
    showDurationBadget() {
      return this.automatic && this.durationInWeeks;
    },
    iterationSortOrder() {
      return this.iterationState === STATUS_CLOSED ? CADENCE_AND_DUE_DATE_DESC : null;
    },
  },
  created() {
    if (
      `${this.$router.currentRoute?.query.createdCadenceId}` ===
      `${getIdFromGraphQLId(this.cadenceId)}`
    ) {
      this.expanded = true;
    }
  },
  methods: {
    fetchMore() {
      if (this.iterations.length === 0 || !this.hasNextPage || this.loading) {
        return;
      }

      // Fetch more data and transform the original result
      this.$apollo.queries.workspace.fetchMore({
        variables: {
          ...this.queryVariables,
          afterCursor: this.pageInfo.endCursor,
        },
        // Transform the previous result with new data
        updateQuery: (previousResult, { fetchMoreResult }) => {
          const newIterations = fetchMoreResult.workspace?.iterations.nodes || [];

          return {
            workspace: {
              id: fetchMoreResult.workspace.id,
              __typename: this.namespaceType,
              iterations: {
                __typename: 'IterationConnection',
                // Merging the list
                nodes: [...previousResult.workspace.iterations.nodes, ...newIterations],
                pageInfo: fetchMoreResult.workspace?.iterations.pageInfo || {},
              },
            },
          };
        },
      });
    },
    path(iterationId) {
      return {
        name: 'iteration',
        params: {
          cadenceId: getIdFromGraphQLId(this.cadenceId),
          iterationId: getIdFromGraphQLId(iterationId),
        },
      };
    },
    showModal() {
      this.$refs.modal.show();
    },
    focusMenu() {
      this.$refs.menu.$el.focus();
    },
    toEditCadence() {
      this.$router.push({
        name: 'edit',
        params: {
          cadenceId: getIdFromGraphQLId(this.cadenceId),
        },
      });
    },
    getIterationPeriod,
  },
};
</script>
<template>
  <li class="gl-py-0!">
    <div class="gl-display-flex gl-align-items-center">
      <gl-button
        variant="link"
        class="gl-font-weight-bold gl-text-body! gl-py-5! gl-px-3! gl-mr-auto gl-min-w-0"
        :aria-expanded="expanded"
        @click="expanded = !expanded"
      >
        <gl-icon
          name="chevron-right"
          class="gl-transition-medium"
          :class="{ 'gl-rotate-90': expanded }"
        /><span class="gl-ml-2">{{ title }}</span>
      </gl-button>
      <span
        v-if="showDurationBadget"
        class="gl-mr-5 gl-display-none gl-sm-display-inline-block"
        data-testid="duration-badge"
      >
        <gl-icon name="clock" class="gl-mr-3" />
        {{ n__('Every week', 'Every %d weeks', durationInWeeks) }}</span
      >
      <gl-dropdown
        v-if="canEditCadence"
        ref="menu"
        icon="ellipsis_v"
        category="tertiary"
        right
        text-sr-only
        no-caret
        data-qa-selector="cadence_options_button"
      >
        <gl-dropdown-item
          v-if="showAddIteration"
          :to="newIteration"
          data-qa-selector="new_iteration_button"
        >
          {{ i18n.addIteration }}
        </gl-dropdown-item>

        <gl-dropdown-item :to="editCadence">
          {{ s__('Iterations|Edit cadence') }}
        </gl-dropdown-item>
        <gl-dropdown-item data-testid="delete-cadence" @click="showModal">
          {{ i18n.deleteCadence }}
        </gl-dropdown-item>
      </gl-dropdown>
      <gl-modal
        ref="modal"
        :modal-id="`${cadenceId}-delete-modal`"
        :title="i18n.modalTitle"
        :ok-title="i18n.modalConfirm"
        ok-variant="danger"
        @hidden="focusMenu"
        @ok="$emit('delete-cadence', cadenceId)"
      >
        {{ i18n.modalText }}
      </gl-modal>
    </div>

    <gl-alert v-if="error" variant="danger" :dismissible="true" @dismiss="error = ''">
      {{ error }}
    </gl-alert>

    <gl-collapse :visible="expanded">
      <div v-if="loading && iterations.length === 0" class="gl-p-5">
        <gl-skeleton-loader :lines="2" />
      </div>

      <gl-infinite-scroll
        v-else-if="iterations.length || loading"
        :fetched-items="iterations.length"
        :max-list-height="250"
        @bottomReached="fetchMore"
      >
        <template #items>
          <ol class="gl-pl-0">
            <li
              v-for="iteration in iterations"
              :key="iteration.id"
              class="gl-bg-gray-10 gl-p-5 gl-border-t-solid gl-border-gray-100 gl-border-t-1"
              data-testid="iteration-item"
            >
              <router-link
                :to="path(iteration.id)"
                data-qa-selector="iteration_item"
                :data-qa-title="getIterationPeriod(iteration)"
              >
                {{ getIterationPeriod(iteration) }}
              </router-link>
              <timebox-status-badge v-if="showStateBadge" :state="iteration.state" />
            </li>
          </ol>
          <div v-if="loading" class="gl-p-5">
            <gl-skeleton-loader :lines="2" />
          </div>
        </template>
      </gl-infinite-scroll>
      <template v-else-if="!loading">
        <p class="gl-px-7">{{ i18n.noResults[iterationState] }}</p>
      </template>
    </gl-collapse>
  </li>
</template>
