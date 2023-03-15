<script>
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';
import GeoSiteReplicationSyncPercentage from './geo_site_replication_sync_percentage.vue';

export default {
  name: 'GeoSiteReplicationCounts',
  i18n: {
    dataType: s__('Geo|Data type'),
    synchronization: s__('Geo|Synchronization'),
    verification: s__('Geo|Verification'),
  },
  components: {
    GeoSiteReplicationSyncPercentage,
  },
  props: {
    siteId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['replicationCountsByDataTypeForSite']),
    replicationOverview() {
      return this.replicationCountsByDataTypeForSite(this.siteId);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-grid geo-site-replication-counts-grid gl-align-items-center gl-mb-3">
      <span>{{ $options.i18n.dataType }}</span>
      <span class="gl-text-right">{{ $options.i18n.synchronization }}</span>
      <span class="gl-text-right">{{ $options.i18n.verification }}</span>
    </div>
    <div
      v-for="type in replicationOverview"
      :key="type.title"
      class="gl-display-grid geo-site-replication-counts-grid gl-align-items-center gl-mb-3"
      data-testid="replication-type"
    >
      <span data-testid="replicable-title">{{ type.title }}</span>
      <geo-site-replication-sync-percentage :values="type.sync" />
      <geo-site-replication-sync-percentage :values="type.verification" />
    </div>
  </div>
</template>
