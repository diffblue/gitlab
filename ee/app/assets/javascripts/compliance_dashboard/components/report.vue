<script>
import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { __ } from '~/locale';
import { thWidthClass } from '~/lib/utils/table_utility';
import complianceViolationsQuery from '../graphql/compliance_violations.query.graphql';
import { mapResponse } from '../graphql/mappers';
import EmptyState from './empty_state.vue';
import MergeCommitsExportButton from './merge_requests/merge_commits_export_button.vue';
import ViolationReason from './violations/reason.vue';

export default {
  name: 'ComplianceReport',
  components: {
    EmptyState,
    GlAlert,
    GlLoadingIcon,
    GlTable,
    MergeCommitsExportButton,
    ViolationReason,
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
  },
  data() {
    return {
      queryError: false,
      violations: [],
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
        return mapResponse(data?.group?.mergeRequestViolations?.nodes || []);
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
  fields: [
    {
      key: 'severity',
      label: __('Severity'),
      thClass: thWidthClass(10),
    },
    {
      key: 'reason',
      label: __('Violation'),
      thClass: thWidthClass(25),
    },
    {
      key: 'mergeRequest',
      label: __('Merge request'),
      thClass: thWidthClass(30),
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
    <gl-table
      v-else-if="hasViolations"
      :fields="$options.fields"
      :items="violations"
      head-variant="white"
      stacked="lg"
      thead-class="gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
    >
      <template #cell(reason)="{ item: { reason, violatingUser } }">
        <violation-reason :reason="reason" :user="violatingUser" />
      </template>
    </gl-table>
    <empty-state v-else :image-path="emptyStateSvgPath" />
  </section>
</template>
