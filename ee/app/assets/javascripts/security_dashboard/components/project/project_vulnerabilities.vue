<script>
import { GlAlert, GlLoadingIcon, GlIntersectionObserver } from '@gitlab/ui';
import produce from 'immer';
import { difference } from 'lodash';
import { Portal } from 'portal-vue';
import securityScannersQuery from 'ee/security_dashboard/graphql/queries/project_security_scanners.query.graphql';
import vulnerabilitiesQuery from 'ee/security_dashboard/graphql/queries/project_vulnerabilities.query.graphql';
import { preparePageInfo } from 'ee/security_dashboard/helpers';
import { VULNERABILITIES_PER_PAGE } from 'ee/security_dashboard/store/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import VulnerabilityList from '../shared/vulnerability_list.vue';
import SecurityScannerAlert from './security_scanner_alert.vue';

export default {
  name: 'ProjectVulnerabilities',
  components: {
    GlAlert,
    GlLoadingIcon,
    GlIntersectionObserver,
    LocalStorageSync,
    Portal,
    SecurityScannerAlert,
    VulnerabilityList,
  },
  inject: {
    vulnerabilityReportAlertsPortal: {
      default: '',
    },
    projectFullPath: {
      default: '',
    },
    hasJiraVulnerabilitiesIntegrationEnabled: {
      default: false,
    },
    canViewFalsePositive: {
      default: false,
    },
  },
  props: {
    filters: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      pageInfo: {},
      vulnerabilities: [],
      scannerAlertDismissed: false,
      securityScanners: {},
      errorLoadingVulnerabilities: false,
      sortBy: 'severity',
      sortDirection: 'desc',
    };
  },
  apollo: {
    vulnerabilities: {
      query: vulnerabilitiesQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
          first: VULNERABILITIES_PER_PAGE,
          sort: this.sort,
          includeExternalIssueLinks: this.hasJiraVulnerabilitiesIntegrationEnabled,
          vetEnabled: this.canViewFalsePositive,
          ...this.filters,
        };
      },
      update: ({ project }) => project?.vulnerabilities.nodes || [],
      result({ data }) {
        this.pageInfo = preparePageInfo(data?.project?.vulnerabilities?.pageInfo);
      },
      error() {
        this.errorLoadingVulnerabilities = true;
      },
      skip() {
        return !this.filters;
      },
    },
    securityScanners: {
      query: securityScannersQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
        };
      },
      error() {
        this.securityScanners = {};
      },
      update({ project = {} }) {
        const { available = [], enabled = [], pipelineRun = [] } = project?.securityScanners || {};
        const translateScannerName = (scannerName) =>
          this.$options.i18n[scannerName] || scannerName;

        return {
          available: available.map(translateScannerName),
          enabled: enabled.map(translateScannerName),
          pipelineRun: pipelineRun.map(translateScannerName),
        };
      },
    },
  },
  computed: {
    isLoadingVulnerabilities() {
      return this.$apollo.queries.vulnerabilities.loading;
    },
    isLoadingFirstVulnerabilities() {
      return this.isLoadingVulnerabilities && this.vulnerabilities.length === 0;
    },
    sort() {
      return `${this.sortBy}_${this.sortDirection}`;
    },
    notEnabledSecurityScanners() {
      const { available = [], enabled = [] } = this.securityScanners;
      return difference(available, enabled);
    },
    noPipelineRunSecurityScanners() {
      const { enabled = [], pipelineRun = [] } = this.securityScanners;
      return difference(enabled, pipelineRun);
    },
    shouldShowScannersAlert() {
      return (
        !this.scannerAlertDismissed &&
        (this.notEnabledSecurityScanners.length > 0 ||
          this.noPipelineRunSecurityScanners.length > 0)
      );
    },
  },
  watch: {
    filters() {
      // Clear out the existing vulnerabilities so that the skeleton loader is shown.
      this.vulnerabilities = [];
    },
    sort() {
      // Clear out the existing vulnerabilities so that the skeleton loader is shown.
      this.vulnerabilities = [];
    },
  },
  methods: {
    fetchNextPage() {
      if (this.pageInfo.hasNextPage) {
        this.$apollo.queries.vulnerabilities.fetchMore({
          variables: { after: this.pageInfo.endCursor },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.project.vulnerabilities.nodes = [
                ...previousResult.project.vulnerabilities.nodes,
                ...draftData.project.vulnerabilities.nodes,
              ];
            });
          },
        });
      }
    },
    handleSortChange({ sortBy, sortDesc }) {
      this.sortDirection = sortDesc ? 'desc' : 'asc';
      this.sortBy = sortBy;
    },
    setScannerAlertDismissed(value) {
      this.scannerAlertDismissed = parseBoolean(value);
    },
  },
  SCANNER_ALERT_DISMISSED_LOCAL_STORAGE_KEY: 'vulnerability_list_scanner_alert_dismissed',
  i18n: {
    API_FUZZING: __('API Fuzzing'),
    CONTAINER_SCANNING: __('Container Scanning'),
    CLUSTER_IMAGE_SCANNING: s__('ciReport|Cluster Image Scanning'),
    COVERAGE_FUZZING: __('Coverage Fuzzing'),
    SECRET_DETECTION: __('Secret Detection'),
    DEPENDENCY_SCANNING: __('Dependency Scanning'),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorLoadingVulnerabilities" :dismissible="false" variant="danger">
      {{
        s__(
          'SecurityReports|Error fetching the vulnerability list. Please check your network connection and try again.',
        )
      }}
    </gl-alert>

    <template v-else>
      <local-storage-sync
        :value="String(scannerAlertDismissed)"
        :storage-key="$options.SCANNER_ALERT_DISMISSED_LOCAL_STORAGE_KEY"
        @input="setScannerAlertDismissed"
      />

      <portal v-if="shouldShowScannersAlert" :to="vulnerabilityReportAlertsPortal">
        <security-scanner-alert
          :not-enabled-scanners="notEnabledSecurityScanners"
          :no-pipeline-run-scanners="noPipelineRunSecurityScanners"
          @dismiss="setScannerAlertDismissed('true')"
        />
      </portal>

      <vulnerability-list
        :is-loading="isLoadingFirstVulnerabilities"
        :filters="filters"
        :vulnerabilities="vulnerabilities"
        @sort-changed="handleSortChange"
      />
      <gl-intersection-observer
        v-if="pageInfo.hasNextPage"
        class="text-center"
        @appear="fetchNextPage"
      >
        <gl-loading-icon v-if="isLoadingVulnerabilities" size="md" />
        <span v-else>&nbsp;</span>
      </gl-intersection-observer>
    </template>
  </div>
</template>
