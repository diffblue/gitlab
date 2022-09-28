<script>
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';
import GeoNodeReplicationSyncPercentage from './geo_node_replication_sync_percentage.vue';

export default {
  name: 'GeoNodeReplicationCounts',
  i18n: {
    dataType: s__('Geo|Data type'),
    synchronization: s__('Geo|Synchronization'),
    verification: s__('Geo|Verification'),
  },
  components: {
    GeoNodeReplicationSyncPercentage,
  },
  props: {
    nodeId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['replicationCountsByDataTypeForNode']),
    replicationOverview() {
      return this.replicationCountsByDataTypeForNode(this.nodeId);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-grid geo-node-replication-counts-grid gl-align-items-center gl-mb-3">
      <span>{{ $options.i18n.dataType }}</span>
      <span class="gl-text-right">{{ $options.i18n.synchronization }}</span>
      <span class="gl-text-right">{{ $options.i18n.verification }}</span>
    </div>
    <div
      v-for="type in replicationOverview"
      :key="type.title"
      class="gl-display-grid geo-node-replication-counts-grid gl-align-items-center gl-mb-3"
      data-testid="replication-type"
    >
      <span data-testid="replicable-title">{{ type.title }}</span>
      <geo-node-replication-sync-percentage :values="type.sync" />
      <geo-node-replication-sync-percentage :values="type.verification" />
    </div>
  </div>
</template>
