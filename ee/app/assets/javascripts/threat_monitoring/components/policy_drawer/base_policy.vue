<script>
import { ENABLED_LABEL, NOT_ENABLED_LABEL } from './constants';

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
      return this.policy?.enabled ? ENABLED_LABEL : NOT_ENABLED_LABEL;
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
