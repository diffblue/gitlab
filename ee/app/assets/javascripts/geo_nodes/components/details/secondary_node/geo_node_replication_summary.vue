<script>
import { GlCard, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import GeoNodeReplicationCounts from './geo_node_replication_counts.vue';
import GeoNodeReplicationStatus from './geo_node_replication_status.vue';
import GeoNodeSyncSettings from './geo_node_sync_settings.vue';

export default {
  name: 'GeoNodeReplicationSummary',
  i18n: {
    replicationSummary: s__('Geo|Replication summary'),
    replicationDetailsButton: s__('Geo|Open replications'),
    replicationStatus: s__('Geo|Replication status'),
    syncSettings: s__('Geo|Synchronization settings'),
  },
  components: {
    GlCard,
    GlButton,
    GeoNodeReplicationStatus,
    GeoNodeSyncSettings,
    GeoNodeReplicationCounts,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-card header-class="gl-display-flex gl-align-items-center">
    <template #header>
      <h5 class="gl-my-0">{{ $options.i18n.replicationSummary }}</h5>
      <gl-button
        class="gl-ml-auto"
        variant="confirm"
        icon="external-link"
        category="secondary"
        :href="node.webGeoProjectsUrl"
        target="_blank"
        >{{ $options.i18n.replicationDetailsButton }}</gl-button
      >
    </template>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.replicationStatus }}</span>
      <geo-node-replication-status class="gl-mt-3" :node="node" />
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.syncSettings }}</span>
      <geo-node-sync-settings class="gl-mt-2" :node="node" />
    </div>
    <geo-node-replication-counts :node-id="node.id" class="gl-mb-5" />
  </gl-card>
</template>
