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
    heading: s__('ComplianceFrameworks|No compliance frameworks are set up yet'),
    description: s__('ComplianceFrameworks|Frameworks that have been added will appear here.'),
    addButton: s__('ComplianceFrameworks|Add framework'),
  },
};
</script>

<template>
  <gl-empty-state
    :description="$options.i18n.description"
    :svg-path="imagePath"
    :primary-button-link="addFrameworkPath"
    :primary-button-text="$options.i18n.addButton"
    compact
    :svg-height="100"
  >
    <template #title>
      <h5 class="gl-mt-0">{{ $options.i18n.heading }}</h5>
    </template>
  </gl-empty-state>
</template>
