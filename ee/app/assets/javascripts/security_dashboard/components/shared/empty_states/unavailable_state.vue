<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

export default {
  components: { GlEmptyState },
  props: {
    svgPath: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: s__(`SecurityReports|Oops, something doesn't seem right.`),
    description: s__(
      `SecurityReports|Either you don't have permission to view this dashboard or the dashboard has not been setup. Please check your permission settings with your administrator or check your dashboard configurations to proceed.`,
    ),
    primaryButtonText: s__('SecurityReports|Learn more about setting up your dashboard'),
  },
  DOC_PATH_SECURITY_CONFIGURATION,
};
</script>

<template>
  <gl-empty-state
    :svg-path="svgPath"
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :primary-button-link="$options.DOC_PATH_SECURITY_CONFIGURATION"
    :primary-button-text="$options.i18n.primaryButtonText"
  />
</template>
