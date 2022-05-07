<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlEmptyState,
  },
  inject: ['dashboardDocumentation', 'emptyStateSvgPath'],
  i18n: {
    title: s__('SecurityReports|Monitor vulnerabilities in your group'),
    description: s__(
      'SecurityReports|Manage and track vulnerabilities identified in projects within your group. Vulnerabilities in projects are shown here when security testing is configured.',
    ),
    secondaryButtonText: __('Learn more'),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="emptyStateSvgPath"
    :description="$options.i18n.description"
    :secondary-button-text="$options.i18n.secondaryButtonText"
    :secondary-button-link="dashboardDocumentation"
  />
</template>
