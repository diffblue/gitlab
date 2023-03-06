<script>
import { mapActions } from 'vuex';
import { REMOVE_NODE_MODAL_ID } from 'ee/geo_nodes/constants';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import GeoNodeActionsDesktop from './geo_node_actions_desktop.vue';
import GeoNodeActionsMobile from './geo_node_actions_mobile.vue';

export default {
  name: 'GeoNodeActions',
  components: {
    GeoNodeActionsMobile,
    GeoNodeActionsDesktop,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions(['prepSiteRemoval']),
    async warnNodeRemoval() {
      await this.prepSiteRemoval(this.node.id);
      this.$root.$emit(BV_SHOW_MODAL, REMOVE_NODE_MODAL_ID);
    },
  },
};
</script>

<template>
  <div>
    <geo-node-actions-mobile class="gl-lg-display-none" :node="node" @remove="warnNodeRemoval" />
    <geo-node-actions-desktop
      class="gl-display-none gl-lg-display-flex"
      :node="node"
      @remove="warnNodeRemoval"
    />
  </div>
</template>
