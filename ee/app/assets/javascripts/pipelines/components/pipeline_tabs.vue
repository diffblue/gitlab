<script>
import { GlTab } from '@gitlab/ui';
import BasePipelineTabs from '~/pipelines/components/pipeline_tabs.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __ } from '~/locale';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import CodequalityReportAppGraphql from 'ee/codequality_report/codequality_report_graphql.vue';
import LicenseComplianceApp from 'ee/license_compliance/components/app.vue';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline/pipeline_security_dashboard.vue';

export default {
  i18n: {
    tabs: {
      securityTitle: __('Security'),
      licenseTitle: __('Licenses'),
      codeQualityTitle: __('Code Quality'),
    },
  },
  components: {
    BasePipelineTabs,
    CodequalityReportApp,
    CodequalityReportAppGraphql,
    GlTab,
    LicenseComplianceApp,
    PipelineSecurityDashboard,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'canGenerateCodequalityReports',
    'codequalityReportDownloadPath',
    'exposeSecurityDashboard',
    'exposeLicenseScanningData',
  ],
  computed: {
    isGraphqlCodeQuality() {
      return this.glFeatures.graphqlCodeQualityFullReport;
    },
    showCodeQualityTab() {
      return Boolean(this.codequalityReportDownloadPath || this.canGenerateCodequalityReports);
    },
    showLicenseTab() {
      return Boolean(this.exposeLicenseScanningData);
    },
    showSecurityTab() {
      return Boolean(this.exposeSecurityDashboard);
    },
  },
};
</script>

<template>
  <base-pipeline-tabs>
    <gl-tab
      v-if="showSecurityTab"
      :title="$options.i18n.tabs.securityTitle"
      data-testid="security-tab"
    >
      <pipeline-security-dashboard />
    </gl-tab>
    <gl-tab
      v-if="showLicenseTab"
      :title="$options.i18n.tabs.licenseTitle"
      data-testid="license-tab"
    >
      <license-compliance-app />
    </gl-tab>
    <gl-tab
      v-if="showCodeQualityTab"
      :title="$options.i18n.tabs.codeQualityTitle"
      data-testid="code-quality-tab"
      data-track-action="click_button"
      data-track-label="get_codequality_report"
    >
      <codequality-report-app-graphql v-if="isGraphqlCodeQuality" />
      <codequality-report-app v-else />
    </gl-tab>
  </base-pipeline-tabs>
</template>
