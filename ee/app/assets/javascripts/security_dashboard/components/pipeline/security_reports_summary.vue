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
import { s__, __ } from '~/locale';
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
  data() {
    return {
      isVisible: true,
    };
  },
  computed: {
    collapseButtonLabel() {
      return this.isVisible ? __('Hide details') : __('Show details');
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
    hasDastArtifactDownload(scanSummary) {
      return (
        Boolean(scanSummary.scannedResourcesCsvPath) ||
        this.findArtifacts(SECURITY_REPORT_TYPE_ENUM_DAST).length > 0
      );
    },
    downloadLink(scanSummary) {
      return scanSummary.scannedResourcesCsvPath || '';
    },
    findArtifacts(scanType) {
      const snakeCase = convertToSnakeCase(scanType.toLowerCase());
      return extractSecurityReportArtifacts([snakeCase], this.jobs);
    },
    buildDastArtifacts(scanSummary) {
      const csvArtifact = {
        name: s__('SecurityReports|scanned resources'),
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
          <strong>{{ s__('SecurityReports|Scan details') }}</strong>
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
    <gl-collapse id="security-reports-summary-details" v-model="isVisible" class="gl-pb-3">
      <div v-for="[scanType, scanSummary] in formattedSummary" :key="scanType" class="row gl-my-3">
        <div class="col-4">
          {{ scanType }}
        </div>
        <div class="col-4">
          <gl-sprintf
            :message="
              n__('%d vulnerability', '%d vulnerabilities', scanSummary.vulnerabilitiesCount)
            "
          />
        </div>
        <div class="col-4">
          <template v-if="scanSummary.scannedResourcesCount !== undefined">
            <gl-button
              v-if="hasScannedResources(scanSummary)"
              v-gl-modal.dastUrl
              icon="download"
              size="small"
              data-testid="modal-button"
            >
              {{ s__('SecurityReports|Download scanned URLs') }}
            </gl-button>

            <template v-else>
              (<gl-sprintf
                :message="
                  n__('%d URL scanned', '%d URLs scanned', scanSummary.scannedResourcesCount)
                "
              />)
            </template>

            <modal
              v-if="hasScannedResources(scanSummary)"
              :scanned-urls="scanSummary.scannedResources.nodes"
              :scanned-resources-count="scanSummary.scannedResourcesCount"
              :download-link="downloadLink(scanSummary)"
            />
          </template>

          <template v-else-if="hasDastArtifactDownload(scanSummary)">
            <security-report-download-dropdown
              :text="s__('SecurityReports|Download results')"
              :artifacts="buildDastArtifacts(scanSummary)"
              data-testid="download-link"
            />
          </template>

          <security-report-download-dropdown
            v-else
            :text="s__('SecurityReports|Download results')"
            :artifacts="findArtifacts(scanType)"
          />
        </div>
      </div>
    </gl-collapse>
  </gl-card>
</template>
