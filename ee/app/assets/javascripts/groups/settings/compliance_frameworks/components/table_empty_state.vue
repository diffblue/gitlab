<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlEmptyState,
  },
  props: {
    imagePath: {
      type: String,
      required: false,
      default: null,
    },
  },
  methods: {
    onAddFramework(event) {
      event.preventDefault();
      this.$emit('addFramework', event);
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
    compact
    :svg-height="100"
  >
    <template #title>
      <h5 class="gl-mt-0">{{ $options.i18n.heading }}</h5>
    </template>
    <template #actions>
      <gl-button category="primary" variant="confirm" class="gl-mb-3" @click="onAddFramework"
        >{{ $options.i18n.addButton }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
