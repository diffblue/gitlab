<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlEmptyState,
  },
  props: {
    imagePath: {
      type: String,
      required: false,
      default: null,
    },
    addFrameworkPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  i18n: {
    heading: s__('ComplianceFrameworks|No compliance frameworks are configured'),
    description: s__('ComplianceFrameworks|Configured compliance frameworks appear here.'),
    addButton: s__('ComplianceFrameworks|Add framework'),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.heading"
    :description="$options.i18n.description"
    :svg-path="imagePath"
    :primary-button-link="addFrameworkPath"
    :primary-button-text="$options.i18n.addButton"
    compact
    :svg-height="110"
    class="gl-mt-5"
  />
</template>
