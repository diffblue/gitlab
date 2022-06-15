<script>
import {
  GlButton,
  GlCard,
  GlCollapse,
  GlCollapseToggleDirective,
  GlSprintf,
  GlModalDirective,
} from '@gitlab/ui';
import { COLLAPSE_SECURITY_REPORTS_SUMMARY_LOCAL_STORAGE_KEY as LOCAL_STORAGE_KEY } from 'ee/security_dashboard/constants';
import { getFormattedSummary } from 'ee/security_dashboard/helpers';
import Modal from 'ee/vue_shared/security_reports/components/dast_modal.vue';
import AccessorUtilities from '~/lib/utils/accessor';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { s__, __, n__ } from '~/locale';
import SecurityReportDownloadDropdown from '~/vue_shared/security_reports/components/security_report_download_dropdown.vue';
import { extractSecurityReportArtifacts } from '~/vue_shared/security_reports/utils';
import {
  SECURITY_REPORT_TYPE_ENUM_DAST,
  REPORT_TYPE_DAST,
} from 'ee/vue_shared/security_reports/constants';

export default {
  name: 'SecurityReportsSummary',
  components: {
    GlButton,
    GlCard,
    GlCollapse,
    GlSprintf,
    Modal,
    SecurityReportDownloadDropdown,
  },
  directives: {
    collapseToggle: GlCollapseToggleDirective,
    GlModal: GlModalDirective,
  },
  props: {
    summary: {
      type: Object,
      required: true,
    },
    jobs: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  i18n: {
    scannedResources: s__('SecurityReports|scanned resources'),
    scanDetails: s__('SecurityReports|Scan details'),
    downloadUrls: s__('SecurityReports|Download scanned URLs'),
    downloadResults: s__('SecurityReports|Download results'),
    hideDetails: __('Hide details'),
    showDetails: __('Show details'),
    vulnerabilities: (count) => n__('%d vulnerability', '%d vulnerabilities', count),
    scannedUrls: (count) => n__('%d URL scanned', '%d URLs scanned', count),
  },
  data() {
    return {
      isVisible: true,
    };
  },
  computed: {
    collapseButtonLabel() {
      return this.isVisible ? this.$options.i18n.hideDetails : this.$options.i18n.showDetails;
    },
    formattedSummary() {
      return getFormattedSummary(this.summary);
    },
  },
  watch: {
    isVisible(isVisible) {
      if (!this.localStorageUsable) {
        return;
      }
      if (isVisible) {
        localStorage.removeItem(LOCAL_STORAGE_KEY);
      } else {
        localStorage.setItem(LOCAL_STORAGE_KEY, '1');
      }
    },
  },
  created() {
    this.localStorageUsable = AccessorUtilities.canUseLocalStorage();
    if (this.localStorageUsable) {
      const shouldHideSummaryDetails = Boolean(localStorage.getItem(LOCAL_STORAGE_KEY));
      this.isVisible = !shouldHideSummaryDetails;
    }
  },
  methods: {
    hasScannedResources(scanSummary) {
      return scanSummary.scannedResources?.nodes?.length > 0;
    },
    hasDastArtifacts() {
      return this.findArtifacts(SECURITY_REPORT_TYPE_ENUM_DAST).length > 0;
    },
    hasDastArtifactDownload(scanType, scanSummary) {
      return (
        scanType === SECURITY_REPORT_TYPE_ENUM_DAST &&
        (Boolean(this.downloadLink(scanSummary)) || this.hasDastArtifacts)
      );
    },
    downloadLink(scanSummary) {
      return scanSummary.scannedResourcesCsvPath || '';
    },
    normalizeScanType(scanType) {
      return convertToSnakeCase(scanType.toLowerCase());
    },
    findArtifacts(scanType) {
      return extractSecurityReportArtifacts([this.normalizeScanType(scanType)], this.jobs);
    },
    buildDastArtifacts(scanSummary) {
      const csvArtifact = {
        name: this.$options.i18n.scannedResources,
        path: this.downloadLink(scanSummary),
        reportType: REPORT_TYPE_DAST,
      };

      return [...this.findArtifacts(SECURITY_REPORT_TYPE_ENUM_DAST), csvArtifact];
    },
  },
};
</script>

<template>
  <gl-card body-class="gl-py-0" header-class="gl-border-b-0">
    <template #header>
      <div class="row">
        <div class="col-7">
          <strong>{{ $options.i18n.scanDetails }}</strong>
        </div>
        <div v-if="localStorageUsable" class="col-5 gl-text-right">
          <gl-button
            v-collapse-toggle.security-reports-summary-details
            data-testid="collapse-button"
          >
            {{ collapseButtonLabel }}
          </gl-button>
        </div>
      </div>
    </template>
    <gl-collapse
      id="security-reports-summary-details"
      v-model="isVisible"
      data-testid="security-reports-summary-details"
      class="gl-pb-3"
    >
      <div v-for="[scanType, scanSummary] in formattedSummary" :key="scanType" class="row gl-my-3">
        <div class="col-4">
          {{ scanType }}
        </div>
        <div class="col-4">
          <gl-sprintf :message="$options.i18n.vulnerabilities(scanSummary.vulnerabilitiesCount)" />
        </div>
        <div class="col-4" :data-testid="`artifact-download-${normalizeScanType(scanType)}`">
          <template v-if="scanSummary.scannedResourcesCount !== undefined">
            <gl-button
              v-if="hasScannedResources(scanSummary)"
              v-gl-modal.dastUrl
              icon="download"
              size="small"
              data-testid="modal-button"
            >
              {{ $options.i18n.downloadUrls }}
            </gl-button>

            <template v-else>
              (<gl-sprintf
                :message="$options.i18n.scannedUrls(scanSummary.scannedResourcesCount)"
              />)
            </template>

            <modal
              v-if="hasScannedResources(scanSummary)"
              :scanned-urls="scanSummary.scannedResources.nodes"
              :scanned-resources-count="scanSummary.scannedResourcesCount"
              :download-link="downloadLink(scanSummary)"
            />
          </template>

          <template v-else-if="hasDastArtifactDownload(scanType, scanSummary)">
            <security-report-download-dropdown
              :text="$options.i18n.downloadResults"
              :artifacts="buildDastArtifacts(scanSummary)"
              data-testid="download-link"
            />
          </template>

          <security-report-download-dropdown
            v-else
            :text="$options.i18n.downloadResults"
            :artifacts="findArtifacts(scanType)"
          />
        </div>
      </div>
    </gl-collapse>
  </gl-card>
</template>
