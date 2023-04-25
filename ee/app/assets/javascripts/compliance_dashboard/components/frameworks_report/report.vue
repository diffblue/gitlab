<script>
import * as Sentry from '@sentry/browser';
import { GlAlert } from '@gitlab/ui';

import { fetchPolicies } from '~/lib/graphql';
import { s__ } from '~/locale';

import {
  GRAPHQL_PAGE_SIZE,
  FRAMEWORKS_FILTER_VALUE_NO_FRAMEWORK,
} from 'ee/compliance_dashboard/constants';
import {
  mapFiltersToUrlParams,
  mapQueryToFilters,
  checkFilterForChange,
} from 'ee/compliance_dashboard/utils';
import complianceFrameworksGroupProjects from '../../graphql/compliance_frameworks_group_projects.query.graphql';
import { mapProjects } from '../../graphql/mappers';
import ProjectsTable from './projects_table.vue';
import Pagination from './pagination.vue';
import Filters from './filters.vue';

export default {
  name: 'ComplianceFrameworkReport',
  components: {
    Filters,
    GlAlert,
    Pagination,
    ProjectsTable,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    rootAncestorPath: {
      type: String,
      required: true,
    },
    newGroupComplianceFrameworkPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasQueryError: false,
      projects: {
        list: [],
        pageInfo: {},
      },
      shouldShowUpdatePopover: false,
    };
  },
  apollo: {
    projects: {
      query: complianceFrameworksGroupProjects,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      variables() {
        return {
          groupPath: this.groupPath,
          ...this.paginationCursors,
          ...this.filterParams,
        };
      },
      update(data) {
        const { nodes, pageInfo } = data?.group?.projects || {};
        return {
          list: mapProjects(nodes),
          pageInfo,
        };
      },
      error(e) {
        Sentry.captureException(e);
        this.hasQueryError = true;
      },
    },
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.projects.loading);
    },
    showPagination() {
      const { hasPreviousPage, hasNextPage } = this.projects.pageInfo || {};
      return hasPreviousPage || hasNextPage;
    },
    paginationCursors() {
      const { before, after } = this.$route.query;

      if (before) {
        return {
          before,
          last: this.perPage,
        };
      }

      return {
        after,
        first: this.perPage,
      };
    },
    filterParams() {
      const { project, framework, frameworkExclude } = this.$route.query;
      const filters = {};

      if (framework && framework === FRAMEWORKS_FILTER_VALUE_NO_FRAMEWORK.id) {
        filters.presenceFilter = frameworkExclude ? 'ANY' : 'NONE';
      } else if (framework) {
        if (frameworkExclude) filters.frameworkNot = framework;
        else filters.framework = framework;
      }

      if (project) filters.project = project;

      return filters;
    },
    filters() {
      return mapQueryToFilters(this.$route.query);
    },
    perPage() {
      return parseInt(this.$route.query.perPage || GRAPHQL_PAGE_SIZE, 10);
    },
  },
  methods: {
    loadPrevPage(previousCursor) {
      this.$router.push({
        query: {
          ...this.$route.query,
          before: previousCursor,
          after: undefined,
        },
      });
    },
    loadNextPage(nextCursor) {
      this.$router.push({
        query: {
          ...this.$route.query,
          before: undefined,
          after: nextCursor,
        },
      });
    },
    onPageSizeChange(perPage) {
      this.$router.push({
        query: {
          ...this.$route.query,
          before: undefined,
          after: undefined,
          perPage,
        },
      });
    },
    onFiltersChanged(filters) {
      const newFilters = mapFiltersToUrlParams(filters);
      if (checkFilterForChange({ currentFilters: this.$route.query, newFilters })) {
        this.$router.push({
          query: {
            ...this.$route.query,
            before: undefined,
            after: undefined,
            ...newFilters,
          },
        });
      } else {
        this.$apollo.queries.projects.refetch();
      }
    },
    showUpdatePopoverIfNeeded() {
      if (this.filters.length) {
        this.shouldShowUpdatePopover = true;
      }
    },
  },
  i18n: {
    queryError: s__(
      'ComplianceReport|Unable to load the compliance framework report. Refresh the page and try again.',
    ),
  },
};
</script>

<template>
  <section>
    <filters
      :value="filters"
      :root-ancestor-path="rootAncestorPath"
      :error="hasQueryError"
      :show-update-popover="shouldShowUpdatePopover"
      @update-popover-hidden="shouldShowUpdatePopover = false"
      @submit="onFiltersChanged"
    />

    <gl-alert v-if="hasQueryError" variant="danger" class="gl-my-3" :dismissible="false">
      {{ $options.i18n.queryError }}
    </gl-alert>

    <projects-table
      v-else
      :is-loading="isLoading"
      :projects="projects.list"
      :root-ancestor-path="rootAncestorPath"
      :group-path="groupPath"
      :new-group-compliance-framework-path="newGroupComplianceFrameworkPath"
      @update="showUpdatePopoverIfNeeded"
    />

    <pagination
      v-if="showPagination"
      :is-loading="isLoading"
      :page-info="projects.pageInfo"
      :per-page="perPage"
      @prev="loadPrevPage"
      @next="loadNextPage"
      @page-size-change="onPageSizeChange"
    />
  </section>
</template>
