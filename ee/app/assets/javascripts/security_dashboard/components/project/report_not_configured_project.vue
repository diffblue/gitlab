<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  inject: [
    'emptyStateSvgPath',
    'securityConfigurationPath',
    'newVulnerabilityPath',
    'canAdminVulnerability',
  ],
  computed: {
    shouldShowNewVulnerabilityButton() {
      return Boolean(this.newVulnerabilityPath) && this.canAdminVulnerability;
    },
  },
  i18n: {
    title: s__('SecurityReports|Monitor vulnerabilities in your project'),
    submitVulnerability: s__('SecurityReports|Submit vulnerability'),
    description: s__(
      'SecurityReports|Manage and track vulnerabilities identified in your project. Vulnerabilities are shown here when security testing is configured.',
    ),
    primaryButtonText: s__('SecurityReports|Configure security testing'),
    secondaryButtonText: __('Learn more'),
  },
  DOC_PATH_SECURITY_CONFIGURATION,
};
</script>

<template>
  <div>
    <div v-if="shouldShowNewVulnerabilityButton" class="gl-my-4 gl-text-right">
      <gl-button :href="newVulnerabilityPath" class="gl-ml-auto" icon="plus">
        {{ $options.i18n.submitVulnerability }}
      </gl-button>
    </div>
    <gl-empty-state
      :title="$options.i18n.title"
      :svg-path="emptyStateSvgPath"
      :description="$options.i18n.description"
      :primary-button-text="$options.i18n.primaryButtonText"
      :primary-button-link="securityConfigurationPath"
      :secondary-button-text="$options.i18n.secondaryButtonText"
      :secondary-button-link="$options.DOC_PATH_SECURITY_CONFIGURATION"
    />
  </div>
</template>
