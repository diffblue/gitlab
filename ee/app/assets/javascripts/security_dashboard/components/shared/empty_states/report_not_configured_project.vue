<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath', 'securityConfigurationPath', 'securityDashboardHelpPath'],
  i18n: {
    title: s__('SecurityReports|Monitor vulnerabilities in your project'),
    description: s__(
      'SecurityReports|Manage and track vulnerabilities identified in your project. Vulnerabilities are shown here when security testing is configured.',
    ),
    primaryButtonText: s__('SecurityReports|Configure security testing'),
    secondaryButtonText: __('Learn more'),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="emptyStateSvgPath"
    :description="$options.i18n.description"
    :primary-button-text="$options.i18n.primaryButtonText"
    :primary-button-link="securityConfigurationPath"
    :secondary-button-text="$options.i18n.secondaryButtonText"
    :secondary-button-link="securityDashboardHelpPath"
  />
</template>
