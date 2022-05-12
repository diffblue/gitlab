<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';

export default {
  components: {
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath'],
  i18n: {
    title: s__('SecurityReports|No vulnerabilities found'),
    primaryButtonText: s__('SecurityReports|Learn more about setting up your dashboard'),
    description: s__(
      `SecurityReports|Although it's rare to have no vulnerabilities, it can happen. Check your settings to make sure you've set up your dashboard correctly.`,
    ),
  },
  DOC_PATH_SECURITY_CONFIGURATION,
};
</script>

<template>
  <gl-empty-state
    class="gl-mt-0"
    :title="$options.i18n.title"
    :svg-path="emptyStateSvgPath"
    :primary-button-link="$options.DOC_PATH_SECURITY_CONFIGURATION"
    :primary-button-text="$options.i18n.primaryButtonText"
    :description="$options.i18n.description"
  />
</template>
