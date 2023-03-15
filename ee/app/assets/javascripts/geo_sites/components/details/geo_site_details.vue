<script>
import GeoSiteCoreDetails from './geo_site_core_details.vue';
import GeoSitePrimaryOtherInfo from './primary_site/geo_site_primary_other_info.vue';
import GeoSiteVerificationInfo from './primary_site/geo_site_verification_info.vue';
import GeoSiteReplicationDetails from './secondary_site/geo_site_replication_details.vue';
import GeoSiteReplicationSummary from './secondary_site/geo_site_replication_summary.vue';
import GeoSiteSecondaryOtherInfo from './secondary_site/geo_site_secondary_other_info.vue';

export default {
  name: 'GeoSiteDetails',
  components: {
    GeoSiteCoreDetails,
    GeoSitePrimaryOtherInfo,
    GeoSiteVerificationInfo,
    GeoSiteReplicationSummary,
    GeoSiteSecondaryOtherInfo,
    GeoSiteReplicationDetails,
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
  <div class="gl-display-grid geo-site-details-grid-columns gl-p-5">
    <geo-site-core-details :site="site" />
    <div
      v-if="site.primary"
      class="gl-display-flex gl-sm-flex-direction-column gl-align-items-flex-start gl-h-full gl-w-full"
    >
      <geo-site-verification-info
        class="gl-flex-grow-1 gl-mb-5 gl-md-mb-0 gl-md-mr-5 gl-h-full gl-w-full"
        :site="site"
      />
      <geo-site-primary-other-info class="gl-flex-grow-1 gl-h-full gl-w-full" :site="site" />
    </div>
    <div v-else class="gl-display-flex gl-flex-direction-column gl-h-full gl-w-full">
      <div
        class="gl-display-flex gl-sm-flex-direction-column gl-align-items-flex-start gl-h-full gl-w-full gl-mb-5"
      >
        <geo-site-replication-summary
          class="gl-flex-grow-1 gl-mb-5 gl-md-mb-0 gl-md-mr-5 gl-h-full gl-w-full"
          :site="site"
        />
        <geo-site-secondary-other-info class="gl-flex-grow-1 gl-h-full gl-w-full" :site="site" />
      </div>
      <geo-site-replication-details :site="site" />
    </div>
  </div>
</template>
