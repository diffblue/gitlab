<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlEmptyState,
  },
  inject: [
    'dashboardType',
    'operationalConfigurationPath',
    'operationalEmptyStateSvgPath',
    'operationalHelpPath',
  ],
  i18n: {
    title: s__('SecurityReports|Monitor vulnerabilities across clusters'),
    description: {
      project: s__(
        'SecurityReports|Manage and track vulnerabilities identified in your Kubernetes clusters. Vulnerabilities appear here after you create a scan execution policy in this project.',
      ),
      group: s__(
        'SecurityReports|Manage and track vulnerabilities identified in your Kubernetes clusters. Vulnerabilities appear here after you create a scan execution policy in any project in this group.',
      ),
      instance: s__(
        'SecurityReports|Manage and track vulnerabilities identified in your Kubernetes clusters. Vulnerabilities appear here after you create a scan execution policy in any project in this instance.',
      ),
    },
    primaryButtonText: s__('SecurityReports|Create policy'),
    secondaryButtonText: __('Learn more'),
  },
  computed: {
    description() {
      return this.$options.i18n.description[this.dashboardType];
    },
    primaryButtonText() {
      return this.dashboardType === 'project' ? this.$options.i18n.primaryButtonText : '';
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="operationalEmptyStateSvgPath"
    :description="description"
    :primary-button-text="primaryButtonText"
    :primary-button-link="operationalConfigurationPath"
    :secondary-button-text="$options.i18n.secondaryButtonText"
    :secondary-button-link="operationalHelpPath"
  />
</template>
