<script>
import * as Sentry from '@sentry/browser';
import { GlAlert } from '@gitlab/ui';

import { s__ } from '~/locale';
import UrlSync from '~/vue_shared/components/url_sync.vue';

import { DEFAULT_PAGINATION_CURSORS, GRAPHQL_PAGE_SIZE } from 'ee/compliance_dashboard/constants';
import { buildDefaultFrameworkFilterParams } from '../../utils';
import complianceFrameworksGroupProjects from '../../graphql/compliance_frameworks_group_projects.query.graphql';
import { mapProjects } from '../../graphql/mappers';
import ProjectsTable from './projects_table.vue';
import Pagination from './pagination.vue';

export default {
  name: 'ComplianceFrameworkReport',
  components: {
    GlAlert,
    Pagination,
    ProjectsTable,
    UrlSync,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const urlQuery = buildDefaultFrameworkFilterParams(window.location.search);
    return {
      urlQuery,
      hasQueryError: false,
      projects: {
        list: [],
        pageInfo: {},
      },
      paginationCursors: {
        ...DEFAULT_PAGINATION_CURSORS,
      },
    };
  },
  apollo: {
    projects: {
      query: complianceFrameworksGroupProjects,
      variables() {
        return {
          groupPath: this.groupPath,
          ...this.paginationCursors,
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
    perPage() {
      return this.paginationCursors.first || this.paginationCursors.last || GRAPHQL_PAGE_SIZE;
    },
  },
  methods: {
    loadPrevPage(startCursor) {
      this.paginationCursors = {
        before: startCursor,
        after: null,
        last: GRAPHQL_PAGE_SIZE,
      };
    },
    loadNextPage(endCursor) {
      this.paginationCursors = {
        before: null,
        after: endCursor,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    onPageSizeChange(perPage) {
      this.paginationCursors = {
        ...DEFAULT_PAGINATION_CURSORS,
        first: perPage,
      };
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
    <gl-alert v-if="hasQueryError" variant="danger" class="gl-my-3" :dismissible="false">
      {{ $options.i18n.queryError }}
    </gl-alert>

    <projects-table v-else :is-loading="isLoading" :projects="projects.list" />

    <pagination
      v-if="showPagination"
      :is-loading="isLoading"
      :page-info="projects.pageInfo"
      :per-page="perPage"
      @prev="loadPrevPage"
      @next="loadNextPage"
      @page-size-change="onPageSizeChange"
    />

    <url-sync :query="urlQuery" url-params-update-strategy="set" />
  </section>
</template>
