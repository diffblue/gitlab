<script>
import { GlTab, GlBadge } from '@gitlab/ui';
import BasePipelineTabs from '~/pipelines/components/pipeline_tabs.vue';
import { codeQualityTabName, licensesTabName, securityTabName } from '~/pipelines/constants';
import { __ } from '~/locale';

export default {
  i18n: {
    tabs: {
      securityTitle: __('Security'),
      codeQualityTitle: __('Code Quality'),
      licensesTitle: __('Licenses'),
    },
  },
  tabNames: {
    security: securityTabName,
    licenses: licensesTabName,
    codeQuality: codeQualityTabName,
  },
  components: {
    BasePipelineTabs,
    GlTab,
    GlBadge,
  },
  inject: [
    'canGenerateCodequalityReports',
    'canManageLicenses',
    'codequalityReportDownloadPath',
    'defaultTabValue',
    'exposeSecurityDashboard',
    'exposeLicenseScanningData',
    'isFullCodequalityReportAvailable',
    'licensesApiPath',
    'licenseManagementApiUrl',
    'licenseScanCount',
    'pipelineIid',
    'securityPoliciesPath',
  ],
  data() {
    return {
      activeTab: this.defaultTabValue,
      codeQualityCount: undefined,
      codeQualityCountFetched: false,
      licenseCount: this.licenseScanCount,
    };
  },
  computed: {
    showCodeQualityTab() {
      return Boolean(
        this.isFullCodequalityReportAvailable &&
          (this.codequalityReportDownloadPath || this.canGenerateCodequalityReports),
      );
    },
    showLicenseTab() {
      return Boolean(this.exposeLicenseScanningData);
    },
    showSecurityTab() {
      return Boolean(this.exposeSecurityDashboard);
    },
  },
  watch: {
    $route(to) {
      this.activeTab = to.name;
    },
  },
  methods: {
    isActive(tabName) {
      return tabName === this.activeTab;
    },
    navigateTo(tabName) {
      this.$router.push({ name: tabName });
    },
    updateCodeQualityCount(count) {
      this.codeQualityCountFetched = true;
      this.codeQualityCount = count;
    },
    updateLicenseCount(count) {
      this.licenseCount = count;
    },
  },
};
</script>

<template>
  <base-pipeline-tabs>
    <gl-tab
      v-if="showSecurityTab"
      :title="$options.i18n.tabs.securityTitle"
      :active="isActive($options.tabNames.security)"
      data-testid="security-tab"
      lazy
      @click="navigateTo($options.tabNames.security)"
    >
      <router-view />
    </gl-tab>
    <gl-tab
      v-if="showLicenseTab"
      :title="$options.i18n.tabs.licensesTitle"
      :active="isActive($options.tabNames.licenses)"
      data-testid="license-tab"
      lazy
      @click="navigateTo($options.tabNames.licenses)"
    >
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.licensesTitle }}</span>
        <gl-badge size="sm" data-testid="license-counter" data-qa-selector="licenses_counter">{{
          licenseCount
        }}</gl-badge>
      </template>

      <router-view
        ref="router-view-licenses"
        :api-url="licenseManagementApiUrl"
        :licenses-api-path="licensesApiPath"
        :security-policies-path="securityPoliciesPath"
        :can-manage-licenses="canManageLicenses"
        :always-open="true"
        report-section-class="split-report-section"
        @updateBadgeCount="updateLicenseCount"
      />
    </gl-tab>
    <gl-tab
      v-if="showCodeQualityTab"
      :title="$options.i18n.tabs.codeQualityTitle"
      :active="isActive($options.tabNames.codeQuality)"
      data-testid="code-quality-tab"
      data-track-action="click_button"
      data-track-label="get_codequality_report"
      lazy
      @click="navigateTo($options.tabNames.codeQuality)"
    >
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.codeQualityTitle }}</span>
        <gl-badge v-if="codeQualityCountFetched" size="sm" data-testid="codequality-counter">{{
          codeQualityCount
        }}</gl-badge>
      </template>

      <router-view ref="router-view-codequality" @updateBadgeCount="updateCodeQualityCount" />
    </gl-tab>
  </base-pipeline-tabs>
</template>
