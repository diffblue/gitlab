<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'emptyStateSvgPath',
    'securityConfigurationPath',
    'securityDashboardHelpPath',
    'newVulnerabilityPath',
    'canAdminVulnerability',
  ],
  computed: {
    shouldShowNewVulnerabilityButton() {
      return (
        this.glFeatures.newVulnerabilityForm &&
        Boolean(this.newVulnerabilityPath) &&
        this.canAdminVulnerability
      );
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
      :secondary-button-link="securityDashboardHelpPath"
    />
  </div>
</template>
