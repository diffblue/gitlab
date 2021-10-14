<script>
import { __ } from '~/locale';

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
      return this.policy?.enabled ? __('Enabled') : __('Disabled');
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
