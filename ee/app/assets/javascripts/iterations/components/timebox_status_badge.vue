<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

const iterationStates = {
  closed: 'closed',
  upcoming: 'upcoming',
  expired: 'expired',
};

export default {
  components: {
    GlBadge,
  },
  props: {
    state: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    status() {
      switch (this.state) {
        case iterationStates.closed:
          return {
            text: __('Closed'),
            variant: 'danger',
          };
        case iterationStates.expired:
          return { text: __('Expired'), variant: 'warning' };
        case iterationStates.upcoming:
          return { text: __('Upcoming'), variant: 'neutral' };
        default:
          return { text: __('Open'), variant: 'success' };
      }
    },
  },
};
</script>

<template>
  <gl-badge :variant="status.variant">
    {{ status.text }}
  </gl-badge>
</template>
