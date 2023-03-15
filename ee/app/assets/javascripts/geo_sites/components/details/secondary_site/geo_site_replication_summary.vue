<script>
import { GlCard, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import GeoSiteReplicationCounts from './geo_site_replication_counts.vue';
import GeoSiteReplicationStatus from './geo_site_replication_status.vue';
import GeoSiteSyncSettings from './geo_site_sync_settings.vue';

export default {
  name: 'GeoSiteReplicationSummary',
  i18n: {
    replicationSummary: s__('Geo|Replication summary'),
    replicationDetailsButton: s__('Geo|Full details'),
    replicationStatus: s__('Geo|Replication status'),
    syncSettings: s__('Geo|Synchronization settings'),
  },
  components: {
    GlCard,
    GlButton,
    GeoSiteReplicationStatus,
    GeoSiteSyncSettings,
    GeoSiteReplicationCounts,
  },
  props: {
    site: {
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
        :href="site.webGeoReplicationDetailsUrl"
        target="_blank"
        >{{ $options.i18n.replicationDetailsButton }}</gl-button
      >
    </template>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.replicationStatus }}</span>
      <geo-site-replication-status class="gl-mt-3" :site="site" />
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.syncSettings }}</span>
      <geo-site-sync-settings class="gl-mt-2" :site="site" />
    </div>
    <geo-site-replication-counts :site-id="site.id" class="gl-mb-5" />
  </gl-card>
</template>
