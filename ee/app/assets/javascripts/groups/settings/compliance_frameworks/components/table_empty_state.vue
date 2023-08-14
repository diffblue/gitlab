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
  },
  i18n: {
    heading: s__('ComplianceFrameworks|No compliance frameworks are set up yet'),
    description: s__(
      'ComplianceFrameworks|Frameworks that have been added will appear here, start by creating a new one above.',
    ),
  },
};
</script>

<template>
  <gl-empty-state class="gl-m-0" :svg-path="imagePath" :svg-height="100">
    <template #title>
      <h6 class="gl-font-lg gl-mt-0">{{ $options.i18n.heading }}</h6>
    </template>
    <template #description>
      <p class="gl-text-secondary">{{ $options.i18n.description }}</p>
    </template>
  </gl-empty-state>
</template>
