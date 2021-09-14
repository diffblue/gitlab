<script>
import { GlIcon } from '@gitlab/ui';
import { escape } from 'lodash';
import { __, n__, sprintf } from '~/locale';

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
    lastAlert: {
      type: Object,
      required: false,
      default: null,
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
      return this.lastAlert
        ? n__('%d Alert:', '%d Alerts:', this.count)
        : n__('%d Alert', '%d Alerts', this.count);
    },
    alertText() {
      return sprintf(
        __('%{title} %{operator} %{threshold}'),
        {
          title: escape(this.lastAlert.title),
          threshold: `${escape(this.lastAlert.threshold)}%`,
          operator: this.lastAlert.operator,
        },
        false,
      );
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
      <span v-if="lastAlert" class="text-secondary">{{ alertText }}</span>
    </div>
  </div>
</template>
