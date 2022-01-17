<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import GeoNodeForm from './geo_node_form.vue';

export default {
  name: 'GeoNodeFormApp',
  components: {
    GeoNodeForm,
    GlBadge,
  },
  props: {
    selectiveSyncTypes: {
      type: Object,
      required: true,
    },
    syncShardsOptions: {
      type: Array,
      required: true,
    },
    node: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    isNodePrimary() {
      return this.node && this.node.primary;
    },
    pageTitle() {
      return this.node ? __('Edit Geo Site') : __('Add New Site');
    },
    pillDetails() {
      return {
        variant: this.isNodePrimary ? 'info' : 'muted',
        label: this.isNodePrimary ? __('Primary') : __('Secondary'),
      };
    },
  },
};
</script>

<template>
  <article class="geo-node-form-container">
    <div class="gl-display-flex gl-align-items-center">
      <h2 class="gl-font-size-h2 gl-my-5">{{ pageTitle }}</h2>
      <gl-badge
        class="rounded-pill gl-font-sm gl-px-3 gl-py-2 gl-ml-3"
        :variant="pillDetails.variant"
        >{{ pillDetails.label }}</gl-badge
      >
    </div>
    <geo-node-form v-bind="$props" />
  </article>
</template>
