<script>
import emptyStateSvg from '@gitlab/svgs/dist/illustrations/issues.svg';
import {
  GlAlert,
  GlButton,
  GlLoadingIcon,
  GlPagination,
  GlTab,
  GlTabs,
  GlEmptyState,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { Namespace } from '../constants';
import IterationsQuery from '../queries/iterations.query.graphql';
import IterationsList from './iterations_list.vue';

const pageSize = 20;

export default {
  i18n: {
    emptyStateDescription: s__(
      'Iterations|Iterations are a way to track issues over a period of time, allowing teams to also track velocity and volatility metrics.',
    ),
    newIteration: s__('Iterations|New iteration'),
    noIterationsFound: s__('Iterations|No iterations found'),
  },
  emptySvgPath: `data:image/svg+xml;utf8,${encodeURIComponent(emptyStateSvg)}`,
  components: {
    IterationsList,
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlPagination,
    GlTab,
    GlTabs,
    GlEmptyState,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    canAdmin: {
      type: Boolean,
      required: false,
      default: false,
    },
    namespaceType: {
      type: String,
      required: false,
      default: Namespace.Group,
      validator: (value) => Object.values(Namespace).includes(value),
    },
    newIterationPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    namespace: {
      query: IterationsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return {
          iterations: data[this.namespaceType]?.iterations?.nodes || [],
          pageInfo: data[this.namespaceType]?.iterations?.pageInfo || {},
        };
      },
      error() {
        this.error = __('Error loading iterations');
      },
    },
  },
  data() {
    return {
      namespace: {
        iterations: [],
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
        },
      },
      pagination: {
        currentPage: 1,
      },
      tabIndex: 0,
      error: '',
    };
  },
  computed: {
    queryVariables() {
      const vars = {
        fullPath: this.fullPath,
        isGroup: this.namespaceType === Namespace.Group,
        state: this.state,
      };

      if (this.pagination.beforeCursor) {
        vars.beforeCursor = this.pagination.beforeCursor;
        vars.lastPageSize = pageSize;
      } else {
        vars.afterCursor = this.pagination.afterCursor;
        vars.firstPageSize = pageSize;
      }

      return vars;
    },
    iterations() {
      return this.namespace.iterations;
    },
    loading() {
      return this.$apollo.queries.namespace.loading;
    },
    state() {
      switch (this.tabIndex) {
        case 0:
          return 'opened';
        case 1:
          return 'closed';
        case 2:
          return 'all';
        default:
          return 'opened';
      }
    },
    prevPage() {
      return Number(this.namespace.pageInfo.hasPreviousPage);
    },
    nextPage() {
      return Number(this.namespace.pageInfo.hasNextPage);
    },
    showEmptyState() {
      return this.iterations.length === 0 && !this.loading;
    },
  },
  methods: {
    handlePageChange(page) {
      const { startCursor, endCursor } = this.namespace.pageInfo;

      if (page > this.pagination.currentPage) {
        this.pagination = {
          afterCursor: endCursor,
          currentPage: page,
        };
      } else {
        this.pagination = {
          beforeCursor: startCursor,
          currentPage: page,
        };
      }
    },
    handleTabChange() {
      this.pagination = { currentPage: 1 };
    },
  },
};
</script>

<template>
  <gl-tabs v-model="tabIndex" @activate-tab="handleTabChange">
    <gl-tab v-for="tab in [__('Open'), __('Closed'), __('All')]" :key="tab">
      <template #title>
        {{ tab }}
      </template>
      <div v-if="loading" class="gl-my-5">
        <gl-loading-icon size="lg" />
      </div>
      <div v-else-if="error">
        <gl-alert variant="danger" @dismiss="error = ''">
          {{ error }}
        </gl-alert>
      </div>

      <gl-empty-state
        v-else-if="showEmptyState"
        :svg-path="$options.emptySvgPath"
        :title="$options.i18n.noIterationsFound"
        :primary-button-text="$options.i18n.newIteration"
        :primary-button-link="newIterationPath"
        :description="$options.i18n.emptyStateDescription"
      />
      <div v-else>
        <iterations-list :iterations="iterations" :namespace-type="namespaceType" />
        <gl-pagination
          v-if="prevPage || nextPage"
          :value="pagination.currentPage"
          :prev-page="prevPage"
          :next-page="nextPage"
          align="center"
          class="gl-pagination gl-mt-3"
          @input="handlePageChange"
        />
      </div>
    </gl-tab>
    <template v-if="canAdmin" #tabs-end>
      <li class="gl-ml-auto gl-display-flex gl-align-items-center">
        <gl-button
          variant="confirm"
          data-qa-selector="new_iteration_button"
          :href="newIterationPath"
        >
          {{ s__('Iterations|New iteration') }}
        </gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
