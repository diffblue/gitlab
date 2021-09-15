<script>
import { mapGetters } from 'vuex';
import { REPOSITORY, BLOB } from 'ee/geo_nodes/constants';
import { __, s__ } from '~/locale';
import GeoNodeReplicationSyncPercentage from './geo_node_replication_sync_percentage.vue';

export default {
  name: 'GeoNodeReplicationCounts',
  i18n: {
    dataType: s__('Geo|Data type'),
    synchronization: s__('Geo|Synchronization'),
    verification: s__('Geo|Verification'),
    git: __('Git'),
    file: __('File'),
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
    ...mapGetters(['verificationInfo', 'syncInfo']),
    replicationOverview() {
      const syncInfoData = this.syncInfo(this.nodeId);
      const verificationInfoData = this.verificationInfo(this.nodeId);

      return [
        {
          title: this.$options.i18n.git,
          sync: this.filterByDataType(syncInfoData, REPOSITORY),
          verification: this.filterByDataType(verificationInfoData, REPOSITORY),
        },
        {
          title: this.$options.i18n.file,
          sync: this.filterByDataType(syncInfoData, BLOB),
          verification: this.filterByDataType(verificationInfoData, BLOB),
        },
      ];
    },
  },
  methods: {
    filterByDataType(data, type) {
      return data.filter((replicable) => replicable.dataType === type).map((d) => d.values);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-align-items-center gl-mb-3">
      <span class="gl-flex-grow-1 gl-flex-basis-0">{{ $options.i18n.dataType }}</span>
      <span class="gl-flex-grow-1 gl-flex-basis-0">{{ $options.i18n.synchronization }}</span>
      <span class="gl-flex-grow-1 gl-flex-basis-0">{{ $options.i18n.verification }}</span>
    </div>
    <div
      v-for="type in replicationOverview"
      :key="type.title"
      class="gl-display-flex gl-align-items-center gl-mb-3"
      data-testid="replication-type"
    >
      <span class="gl-flex-grow-1 gl-flex-basis-0" data-testid="replicable-title">{{
        type.title
      }}</span>
      <geo-node-replication-sync-percentage :values="type.sync" />
      <geo-node-replication-sync-percentage :values="type.verification" />
    </div>
  </div>
</template>
