<script>
import {
  GlAlert,
  GlTable,
  GlIcon,
  GlLink,
  GlBadge,
  GlLoadingIcon,
  GlKeysetPagination,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { formatDate } from '~/lib/utils/datetime_utility';
import getProjectComplianceStandardsAdherence from '../../graphql/compliance_standards_adherence.query.graphql';
import { DEFAULT_PAGINATION_CURSORS, GRAPHQL_PAGE_SIZE } from '../../constants';
import {
  FAIL_STATUS,
  STANDARDS_ADHERENCE_CHECK_LABELS,
  STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS,
  STANDARDS_ADHERENCE_STANARD_LABELS,
  NO_STANDARDS_ADHERENCES_FOUND,
  STANDARDS_ADHERENCE_FETCH_ERROR,
} from './constants';
import FixSuggestionsSidebar from './fix_suggestions_sidebar.vue';

export default {
  name: 'ComplianceStandardsAdherenceTable',
  components: {
    GlAlert,
    GlTable,
    GlIcon,
    GlLink,
    GlBadge,
    GlLoadingIcon,
    GlKeysetPagination,
    FixSuggestionsSidebar,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasStandardsAdherenceFetchError: false,
      adherences: {
        list: [],
        pageInfo: {},
      },
      drawerId: null,
      drawerAdherence: {},
      paginationCursors: {
        ...DEFAULT_PAGINATION_CURSORS,
      },
    };
  },
  apollo: {
    adherences: {
      query: getProjectComplianceStandardsAdherence,
      variables() {
        return {
          fullPath: this.groupPath,
          ...this.paginationCursors,
        };
      },
      update(data) {
        const { nodes, pageInfo } = data?.group?.projectComplianceStandardsAdherence || {};
        return {
          list: nodes,
          pageInfo,
        };
      },
      error(e) {
        Sentry.captureException(e);
        this.hasStandardsAdherenceFetchError = true;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.adherences.loading;
    },
    showDrawer() {
      return this.drawerId !== null;
    },
    showPagination() {
      const { hasPreviousPage, hasNextPage } = this.adherences.pageInfo || {};
      return hasPreviousPage || hasNextPage;
    },
  },
  methods: {
    adherenceCheckName(check) {
      return STANDARDS_ADHERENCE_CHECK_LABELS[check];
    },
    adherenceCheckDescription(check) {
      return STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS[check];
    },
    adherenceStandardLabel(standard) {
      return STANDARDS_ADHERENCE_STANARD_LABELS[standard];
    },
    formatDate(dateString) {
      return formatDate(dateString, 'mmm d, yyyy');
    },
    isFailedStatus(status) {
      return status === FAIL_STATUS;
    },
    toggleDrawer(item) {
      if (this.drawerId === item.id) {
        this.closeDrawer();
      } else {
        this.openDrawer(item);
      }
    },
    openDrawer(item) {
      this.drawerAdherence = item;
      this.drawerId = item.id;
    },
    closeDrawer() {
      this.drawerAdherence = {};
      this.drawerId = null;
    },
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
  },
  fields: [
    {
      key: 'status',
      sortable: false,
      tdClass: 'gl-w-15',
    },
    {
      key: 'project',
      sortable: false,
    },
    {
      key: 'checks',
      sortable: false,
    },
    {
      key: 'standard',
      sortable: false,
    },
    {
      key: 'lastScanned',
      sortable: false,
      tdClass: 'gl-w-20',
    },
    {
      key: 'fixSuggestions',
      sortable: false,
      tdClass: 'gl-w-20',
    },
  ],
  noStandardsAdherencesFound: NO_STANDARDS_ADHERENCES_FOUND,
  standardsAdherenceFetchError: STANDARDS_ADHERENCE_FETCH_ERROR,
};
</script>

<template>
  <section>
    <gl-alert
      v-if="hasStandardsAdherenceFetchError"
      variant="danger"
      class="gl-mt-3"
      :dismissible="false"
    >
      {{ $options.standardsAdherenceFetchError }}
    </gl-alert>
    <gl-table
      :fields="$options.fields"
      :items="adherences.list"
      :busy="isLoading"
      :empty-text="$options.noStandardsAdherencesFound"
      show-empty
    >
      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="gl-my-5" />
      </template>
      <template #cell(status)="{ item: { status } }">
        <span v-if="isFailedStatus(status)" class="gl-text-red-500">
          <gl-icon name="status_failed" /> {{ __('Fail') }}
        </span>
        <span v-else class="gl-text-green-500">
          <gl-icon name="status_success" /> {{ __('Success') }}
        </span>
      </template>

      <template #cell(project)="{ item: { project } }">
        <div>{{ project.name }}</div>
        <div v-for="framework in project.complianceFrameworks.nodes" :key="framework.id">
          <gl-badge size="sm" class="gl-mt-3"> {{ framework.name }}</gl-badge>
        </div>
      </template>

      <template #cell(checks)="{ item: { checkName } }">
        <div class="gl-font-weight-bold">{{ adherenceCheckName(checkName) }}</div>
        <div class="gl-mt-2">{{ adherenceCheckDescription(checkName) }}</div>
      </template>

      <template #cell(standard)="{ item: { standard } }">
        {{ adherenceStandardLabel(standard) }}
      </template>

      <template #cell(lastScanned)="{ item: { updatedAt } }">
        {{ formatDate(updatedAt) }}
      </template>

      <template #cell(fixSuggestions)="{ item }">
        <gl-link @click="toggleDrawer(item)">{{
          s__('ComplianceStandardsAdherence|View details')
        }}</gl-link>
      </template>
    </gl-table>
    <fix-suggestions-sidebar
      :group-path="groupPath"
      :show-drawer="showDrawer"
      :adherence="drawerAdherence"
      @close="closeDrawer"
    />
    <div v-if="showPagination" class="gl-display-flex gl-justify-content-center">
      <gl-keyset-pagination
        v-bind="adherences.pageInfo"
        :disabled="isLoading"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        @prev="loadPrevPage"
        @next="loadNextPage"
      />
    </div>
  </section>
</template>
