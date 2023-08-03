<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    alertClasses() {
      return {
        'text-tertiary': this.count <= 0,
        'text-warning': this.count > 0,
      };
    },
    alertCount() {
      return n__('%d Alert', '%d Alerts', this.count);
    },
  },
};
</script>

<template>
  <div class="dashboard-card-alert row">
    <div class="col-12">
      <gl-icon
        :class="alertClasses"
        class="align-text-bottom js-dashboard-alerts-icon"
        name="warning"
      />
      <span class="js-alert-count text-secondary gl-ml-2"> {{ alertCount }} </span>
    </div>
  </div>
</template>
