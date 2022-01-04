<script>
import {
  GlEmptyState,
  GlLoadingIcon,
  GlLink,
  GlIcon,
  GlTab,
  GlTabs,
  GlBadge,
  GlAlert,
} from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import SbomBanner from 'ee/sbom_banner/components/app.vue';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import { getLocationHash } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { LICENSE_LIST } from '../store/constants';
import DetectedLicensesTable from './detected_licenses_table.vue';
import PipelineInfo from './pipeline_info.vue';

export default {
  name: 'LicenseComplianceApp',
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlLink,
    DetectedLicensesTable,
    PipelineInfo,
    GlIcon,
    GlTab,
    GlTabs,
    GlBadge,
    GlAlert,
    SbomBanner,
    LicenseManagement,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['sbomSurveySvgPath', 'emptyStateSvgPath', 'documentationPath'],
  data() {
    return {
      tabIndex: this.activeTabIndex(),
    };
  },
  tabNames: ['licenses', 'policies'],
  computed: {
    ...mapState(LICENSE_LIST, ['initialized', 'licenses', 'reportInfo', 'listTypes', 'pageInfo']),
    ...mapState(LICENSE_MANAGEMENT, ['managedLicenses']),
    ...mapGetters(LICENSE_LIST, ['isJobSetUp', 'isJobFailed', 'hasPolicyViolations']),
    hasEmptyState() {
      return Boolean(!this.isJobSetUp || this.isJobFailed);
    },
    licenseCount() {
      return this.pageInfo.total;
    },
    policyCount() {
      return this.managedLicenses.length;
    },
    isDetectedProjectTab() {
      return this.tabIndex === 0;
    },
  },
  watch: {
    tabIndex: {
      handler(newTabIndex) {
        window.location.hash = this.$options.tabNames[newTabIndex];
      },
      // this ensures that the hash will be set on creation if it is empty
      immediate: true,
    },
  },
  created() {
    this.fetchLicenses();
  },
  methods: {
    ...mapActions(LICENSE_LIST, ['fetchLicenses']),
    activeTabIndex() {
      const activeTabIndex = this.$options.tabNames.indexOf(getLocationHash());

      return activeTabIndex !== -1 ? activeTabIndex : 0;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!initialized" size="md" class="mt-4" />

  <gl-empty-state
    v-else-if="hasEmptyState"
    :title="s__('Licenses|View license details for your project')"
    :svg-path="emptyStateSvgPath"
    data-qa-selector="license_compliance_empty_state_description_content"
  >
    <template #description>
      {{
        s__(
          'Licenses|The license list details information about the licenses used within your project.',
        )
      }}
      <gl-link target="_blank" :href="documentationPath">
        {{ __('More Information') }}
      </gl-link>
    </template>
  </gl-empty-state>

  <div v-else>
    <gl-alert v-if="hasPolicyViolations" class="mt-3" variant="warning" :dismissible="false">
      {{
        s__(
          "Licenses|Detected licenses that are out-of-compliance with the project's assigned policies",
        )
      }}
    </gl-alert>
    <sbom-banner :sbom-survey-svg-path="sbomSurveySvgPath" />
    <header class="my-3">
      <h2 class="h4 mb-1 gl-display-flex gl-align-items-center">
        {{ s__('Licenses|License Compliance') }}
        <gl-link :href="documentationPath" class="gl-ml-3" target="_blank">
          <gl-icon name="question" />
        </gl-link>
      </h2>

      <pipeline-info
        v-if="isDetectedProjectTab"
        :path="reportInfo.jobPath"
        :timestamp="reportInfo.generatedAt"
      />
      <template v-else>{{ s__('Licenses|Specified policies in this project') }}</template>
    </header>

    <gl-tabs v-model="tabIndex" content-class="pt-0">
      <gl-tab data-testid="licensesTab">
        <template #title>
          <span data-testid="licensesTabTitle">{{ s__('Licenses|Detected in Project') }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ licenseCount }}</gl-badge>
        </template>

        <detected-licenses-table />
      </gl-tab>

      <gl-tab data-testid="policiesTab">
        <template #title>
          <span data-qa-selector="policies_tab" data-testid="policiesTabTitle">{{
            s__('Licenses|Policies')
          }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ policyCount }}</gl-badge>
        </template>

        <license-management />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
