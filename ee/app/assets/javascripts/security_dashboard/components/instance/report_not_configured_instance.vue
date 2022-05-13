<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

export default {
  components: {
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath', 'instanceDashboardSettingsPath'],
  i18n: {
    title: s__('SecurityReports|Monitor vulnerabilities in all of your projects'),
    description: s__(
      'SecurityReports|Manage and track vulnerabilities identified in your selected projects. Vulnerabilities for selected projects with security testing configured are shown here.',
    ),
    primaryButtonText: __('Add projects'),
    secondaryButtonText: __('Learn more'),
  },
  DOC_PATH_SECURITY_CONFIGURATION,
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="emptyStateSvgPath"
    :description="$options.i18n.description"
    :primary-button-text="$options.i18n.primaryButtonText"
    :primary-button-link="instanceDashboardSettingsPath"
    :secondary-button-text="$options.i18n.secondaryButtonText"
    :secondary-button-link="$options.DOC_PATH_SECURITY_CONFIGURATION"
  />
</template>
