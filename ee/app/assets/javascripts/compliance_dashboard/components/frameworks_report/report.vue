<script>
import * as Sentry from '@sentry/browser';
import { GlAlert } from '@gitlab/ui';

import { s__ } from '~/locale';

import { GRAPHQL_PAGE_SIZE } from 'ee/compliance_dashboard/constants';
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
  },
  props: {
    groupPath: {
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

    <projects-table
      v-else
      :is-loading="isLoading"
      :projects="projects.list"
      :group-path="groupPath"
      :new-group-compliance-framework-path="newGroupComplianceFrameworkPath"
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
