<script>
import { GlBadge } from '@gitlab/ui';

import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';

export const VARIANTS = {
  confirmed: 'danger',
  resolved: 'success',
  detected: 'warning',
  dismissed: 'neutral',
};

export default {
  components: {
    GlBadge,
  },
  props: {
    state: {
      type: String,
      required: true,
      validator: (state) => Object.keys(VARIANTS).includes(state),
    },
  },
  computed: {
    stateName() {
      return VULNERABILITY_STATES[this.state];
    },
    stateVariant() {
      return VARIANTS[this.state];
    },
  },
};
</script>

<template>
  <gl-badge :variant="stateVariant">
    {{ stateName }}
  </gl-badge>
</template>
