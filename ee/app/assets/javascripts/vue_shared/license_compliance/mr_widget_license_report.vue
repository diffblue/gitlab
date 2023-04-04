<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlLink, GlIcon, GlButton } from '@gitlab/ui';
import api from '~/api';
import { componentNames, iconComponentNames } from 'ee/ci/reports/components/issue_body';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import ReportItem from '~/ci/reports/components/report_item.vue';
import ReportSection from '~/ci/reports/components/report_section.vue';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';
import { setupStore } from './store';

export default {
  name: 'MrWidgetLicenses',
  componentNames,
  iconComponentNames,
  components: {
    GlButton,
    GlLink,
    ReportItem,
    ReportSection,
    SmartVirtualList,
    GlIcon,
  },
  mixins: [reportsMixin],
  props: {
    fullReportPath: {
      type: String,
      required: false,
      default: null,
    },
    apiUrl: {
      type: String,
      required: true,
    },
    licensesApiPath: {
      type: String,
      required: false,
      default: '',
    },
    approvalsApiPath: {
      type: String,
      required: false,
      default: '',
    },
    canManageLicenses: {
      type: Boolean,
      required: true,
    },
    reportSectionClass: {
      type: String,
      required: false,
      default: '',
    },
    alwaysOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    licenseComplianceDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    securityPoliciesPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  typicalReportItemHeight: 26,
  maxShownReportItems: 20,
  computed: {
    ...mapState(LICENSE_MANAGEMENT, ['loadLicenseReportError']),
    ...mapGetters(LICENSE_MANAGEMENT, [
      'licenseReport',
      'isLoading',
      'licenseSummaryText',
      'reportContainsDeniedLicense',
      'licenseReportGroups',
    ]),
    hasLicenseReportIssues() {
      const { licenseReport } = this;
      return licenseReport && licenseReport.length > 0;
    },
    licenseReportStatus() {
      return this.checkReportStatus(this.isLoading, this.loadLicenseReportError);
    },
    showActionButtons() {
      return this.securityPoliciesPath !== null || this.fullReportPath !== null;
    },
  },
  watch: {
    licenseReport() {
      this.$emit('updateBadgeCount', this.licenseReport.length);
    },
  },
  beforeCreate() {
    setupStore(this.$store);
  },
  mounted() {
    const { apiUrl, canManageLicenses, licensesApiPath, approvalsApiPath } = this;

    this.setAPISettings({
      apiUrlManageLicenses: apiUrl,
      canManageLicenses,
      licensesApiPath,
      approvalsApiPath,
    });

    this.fetchParsedLicenseReport();
    this.fetchLicenseCheckApprovalRule();
  },
  methods: {
    trackVisitedPath(trackAction) {
      api.trackRedisHllUserEvent(trackAction);
      api.trackRedisCounterEvent(trackAction);
    },
    ...mapActions(LICENSE_MANAGEMENT, [
      'setAPISettings',
      'fetchParsedLicenseReport',
      'fetchLicenseCheckApprovalRule',
    ]),
  },
};
</script>
<template>
  <div>
    <report-section
      :status="licenseReportStatus"
      :loading-text="licenseSummaryText"
      :error-text="licenseSummaryText"
      :neutral-issues="licenseReport"
      :has-issues="hasLicenseReportIssues"
      :component="$options.componentNames.LicenseIssueBody"
      :class="reportSectionClass"
      track-action="users_expanding_testing_license_compliance_report"
      :always-open="alwaysOpen"
      class="license-report-widget mr-report"
      data-qa-selector="license_report_widget"
    >
      <template #body>
        <smart-virtual-list
          ref="reportSectionBody"
          :size="$options.typicalReportItemHeight"
          :length="licenseReport.length"
          :remain="$options.maxShownReportItems"
          class="report-block-container"
          wtag="ul"
          wclass="report-block-list my-1"
        >
          <template v-for="(licenseReportGroup, index) in licenseReportGroups">
            <li
              :key="licenseReportGroup.name"
              :class="['mx-1', 'mb-1', index > 0 ? 'mt-3' : '']"
              data-testid="report-heading"
            >
              <h2 class="h5 m-0">{{ licenseReportGroup.name }}</h2>
              <p class="m-0">{{ licenseReportGroup.description }}</p>
            </li>
            <report-item
              v-for="license in licenseReportGroup.licenses"
              :key="license.name"
              :issue="license"
              :status-icon-size="12"
              :status="license.status"
              :component="$options.componentNames.LicenseIssueBody"
              :icon-component="$options.iconComponentNames.LicenseStatusIcon"
              :show-report-section-status-icon="true"
              class="gl-m-2"
            />
          </template>
        </smart-virtual-list>
      </template>
      <template #success>
        <div class="pr-3">
          {{ licenseSummaryText }}
          <gl-link
            v-if="reportContainsDeniedLicense && licenseComplianceDocsPath"
            :href="licenseComplianceDocsPath"
            data-testid="security-approval-help-link"
            target="_blank"
          >
            <gl-icon :size="12" name="question-o" />
          </gl-link>
        </div>
      </template>
      <template v-if="showActionButtons" #action-buttons="{ isCollapsible }">
        <gl-button
          v-if="fullReportPath"
          :href="fullReportPath"
          class="gl-mr-3"
          icon="external-link"
          target="_blank"
          data-testid="full-report-button"
          @click="trackVisitedPath('users_visiting_testing_license_compliance_full_report')"
        >
          {{ s__('ciReport|View full report') }}
        </gl-button>
        <gl-button
          v-if="securityPoliciesPath"
          data-testid="manage-licenses-button"
          :class="{ 'gl-mr-3': isCollapsible }"
          :href="securityPoliciesPath"
          data-qa-selector="manage_licenses_button"
          @click="trackVisitedPath('users_visiting_testing_manage_license_compliance')"
        >
          {{ s__('ciReport|Manage licenses') }}
        </gl-button>
      </template>
    </report-section>
  </div>
</template>
