<script>
import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { __ } from '~/locale';
import { thWidthClass } from '~/lib/utils/table_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import complianceViolationsQuery from '../graphql/compliance_violations.query.graphql';
import { mapViolations } from '../graphql/mappers';
import EmptyState from './empty_state.vue';
import MergeCommitsExportButton from './merge_requests/merge_commits_export_button.vue';
import MergeRequestDrawer from './drawer.vue';
import ViolationReason from './violations/reason.vue';
import ViolationFilter from './violations/filter.vue';

export default {
  name: 'ComplianceReport',
  components: {
    EmptyState,
    GlAlert,
    GlLoadingIcon,
    GlTable,
    MergeCommitsExportButton,
    MergeRequestDrawer,
    ViolationReason,
    TimeAgoTooltip,
    ViolationFilter,
    UrlSync,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    groupPath: {
      type: String,
      required: true,
    },
    defaultQuery: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      urlQuery: {},
      queryError: false,
      violations: [],
      showDrawer: false,
      drawerMergeRequest: {},
      drawerProject: {},
    };
  },
  apollo: {
    violations: {
      query: complianceViolationsQuery,
      variables() {
        return {
          fullPath: 'groups-path',
        };
      },
      update(data) {
        return mapViolations(data?.group?.mergeRequestViolations?.nodes);
      },
      error(e) {
        Sentry.captureException(e);
        this.queryError = true;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.violations.loading;
    },
    hasViolations() {
      return this.violations.length > 0;
    },
    hasMergeCommitsCsvExportPath() {
      return this.mergeCommitsCsvExportPath !== '';
    },
  },
  methods: {
    toggleDrawer(rows) {
      const { id, mergeRequest, project } = rows[0] || {};

      if (!mergeRequest || (this.showDrawer && id === this.drawerMergeRequest.id)) {
        this.closeDrawer();
      } else {
        this.openDrawer(id, mergeRequest, project);
      }
    },
    openDrawer(id, mergeRequest, project) {
      this.showDrawer = true;
      this.drawerMergeRequest = mergeRequest;
      this.drawerProject = project;
    },
    closeDrawer() {
      this.showDrawer = false;
      // Refs are required by BTable to manipulate the selection
      // issue: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1531
      this.$refs.table.$children[0].clearSelected();
      this.drawerMergeRequest = {};
      this.drawerProject = {};
    },
    updateUrlQuery({ projectIds = [], ...rest }) {
      this.urlQuery = {
        // Clear the URL param when the id array is empty
        projectIds: projectIds.length > 0 ? projectIds : null,
        ...rest,
      };
    },
  },
  fields: [
    {
      key: 'severity',
      label: __('Severity'),
      thClass: thWidthClass(10),
    },
    {
      key: 'reason',
      label: __('Violation'),
      thClass: thWidthClass(15),
    },
    {
      key: 'mergeRequest',
      label: __('Merge request'),
      thClass: thWidthClass(40),
    },
    {
      key: 'mergedAt',
      label: __('Date merged'),
      thClass: thWidthClass(20),
    },
  ],
  i18n: {
    heading: __('Compliance report'),
    subheading: __(
      'The compliance report shows the merge request violations merged in protected environments.',
    ),
    queryError: __(
      'Retrieving the compliance report failed. Please refresh the page and try again.',
    ),
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <section>
    <header class="gl-mb-6">
      <div class="gl-mt-5 d-flex">
        <h2 class="gl-flex-grow-1 gl-my-0">{{ $options.i18n.heading }}</h2>
        <merge-commits-export-button
          v-if="hasMergeCommitsCsvExportPath"
          :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
        />
      </div>
      <p class="gl-mt-5">{{ $options.i18n.subheading }}</p>
    </header>
    <gl-loading-icon v-if="isLoading" size="xl" />
    <gl-alert
      v-else-if="queryError"
      variant="danger"
      :dismissible="false"
      :title="$options.i18n.queryError"
    />
    <template v-else-if="hasViolations">
      <violation-filter
        :group-path="groupPath"
        :default-query="defaultQuery"
        @filters-changed="updateUrlQuery"
      />
      <gl-table
        ref="table"
        :fields="$options.fields"
        :items="violations"
        head-variant="white"
        stacked="lg"
        select-mode="single"
        selectable
        hover
        selected-variant="primary"
        thead-class="gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
        @row-selected="toggleDrawer"
      >
        <template #cell(reason)="{ item: { reason, violatingUser } }">
          <violation-reason :reason="reason" :user="violatingUser" />
        </template>
        <template #cell(mergeRequest)="{ item: { mergeRequest } }">
          {{ mergeRequest.title }}
        </template>
        <template #cell(mergedAt)="{ item: { mergeRequest } }">
          <time-ago-tooltip :time="mergeRequest.mergedAt" />
        </template>
      </gl-table>
    </template>
    <empty-state v-else :image-path="emptyStateSvgPath" />
    <merge-request-drawer
      :show-drawer="showDrawer"
      :merge-request="drawerMergeRequest"
      :project="drawerProject"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDrawer"
    />
    <url-sync :query="urlQuery" />
  </section>
</template>
