<script>
import { s__ } from '~/locale';

export default {
  props: {
    policy: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    statusLabel() {
      return this.policy?.enabled
        ? s__('SecurityOrchestration|Enabled')
        : s__('SecurityOrchestration|Disabled');
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-mt-3">{{ __('Type') }}</h5>
    <p data-testid="policy-type">
      <slot name="type"></slot>
    </p>
    <slot v-bind="{ statusLabel }"></slot>
  </div>
</template>
