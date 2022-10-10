<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import GeoNodeActions from './geo_node_actions.vue';
import GeoNodeHealthStatus from './geo_node_health_status.vue';
import GeoNodeLastUpdated from './geo_node_last_updated.vue';

export default {
  name: 'GeoNodeHeader',
  i18n: {
    expand: __('Expand'),
    collapse: __('Collapse'),
  },
  components: {
    GlButton,
    GeoNodeHealthStatus,
    GeoNodeLastUpdated,
    GeoNodeActions,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    chevronIcon() {
      return this.collapsed ? 'chevron-right' : 'chevron-down';
    },
    chevronLabel() {
      return this.collapsed ? this.$options.i18n.expand : this.$options.i18n.collapse;
    },
    statusCheckTimestamp() {
      return this.node.lastSuccessfulStatusCheckTimestamp
        ? this.node.lastSuccessfulStatusCheckTimestamp * 1000 // Converting timestamp to ms
        : null;
    },
  },
};
</script>

<template>
  <div
    class="gl-display-grid geo-node-header-grid-columns gl-bg-gray-10 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100 gl-py-3 gl-px-5"
  >
    <div class="gl-display-flex gl-align-items-center">
      <gl-button
        class="gl-mr-3 gl-p-0!"
        category="tertiary"
        variant="confirm"
        :icon="chevronIcon"
        :aria-label="chevronLabel"
        @click="$emit('collapse')"
      />
      <div
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-md-align-items-center gl-flex-grow-1"
      >
        <div class="gl-display-flex gl-align-items-center gl-flex-grow-1 gl-flex-basis-0">
          <h4 class="gl-font-lg">{{ node.name }}</h4>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-flex-grow-2 gl-flex-basis-0">
          <geo-node-health-status :status="node.healthStatus" />
          <geo-node-last-updated
            v-if="statusCheckTimestamp"
            class="gl-ml-2"
            :status-check-timestamp="statusCheckTimestamp"
            :primary="node.primary"
          />
        </div>
      </div>
    </div>
    <div class="gl-display-flex gl-align-items-center gl-justify-content-end">
      <geo-node-actions :node="node" />
    </div>
  </div>
</template>
