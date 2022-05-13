<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

export default {
  components: {
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath'],
  i18n: {
    title: s__('SecurityReports|Monitor vulnerabilities in your group'),
    description: s__(
      'SecurityReports|Manage and track vulnerabilities identified in projects within your group. Vulnerabilities in projects are shown here when security testing is configured.',
    ),
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
    :secondary-button-text="$options.i18n.secondaryButtonText"
    :secondary-button-link="$options.DOC_PATH_SECURITY_CONFIGURATION"
  />
</template>
