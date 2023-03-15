<script>
import { GlLink } from '@gitlab/ui';
import GeoSiteProgressBar from 'ee/geo_sites/components/details/geo_site_progress_bar.vue';
import { s__, __ } from '~/locale';

export default {
  name: 'GeoSiteReplicationDetailsResponsive',
  i18n: {
    dataType: __('Data type'),
    component: __('Component'),
    status: __('Status'),
    syncStatus: s__('Geo|Synchronization status'),
    verifStatus: s__('Geo|Verification status'),
    popoverHelpText: s__(
      'Geo|Replicated data is verified with the secondary site(s) using checksums',
    ),
    learnMore: __('Learn more'),
    nA: __('Not applicable.'),
    progressBarSyncTitle: s__('Geo|%{component} synced'),
    progressBarVerifTitle: s__('Geo|%{component} verified'),
    verified: s__('Geo|Verified'),
    nothingToVerify: s__('Geo|Nothing to verify'),
  },
  components: {
    GlLink,
    GeoSiteProgressBar,
  },
  props: {
    siteId: {
      type: Number,
      required: false,
      default: 0,
    },
    replicationItems: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-display-grid geo-site-replication-details-grid-columns gl-bg-gray-10 gl-p-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
      data-testid="replication-details-header"
    >
      <slot name="title" :translations="$options.i18n">
        <span class="gl-font-weight-bold">{{ $options.i18n.dataType }}</span>
        <span class="gl-font-weight-bold">{{ $options.i18n.component }}</span>
        <span class="gl-font-weight-bold">{{ $options.i18n.syncStatus }}</span>
        <span class="gl-font-weight-bold">{{ $options.i18n.verifStatus }}</span>
      </slot>
    </div>
    <div
      v-for="item in replicationItems"
      :key="item.component"
      class="gl-display-grid geo-site-replication-details-grid-columns gl-p-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
      data-testid="replication-details-item"
    >
      <slot :item="item" :translations="$options.i18n">
        <span class="gl-mr-5">{{ item.dataTypeTitle }}</span>
        <div class="gl-mr-5" data-testid="replicable-component">
          <gl-link v-if="item.replicationView" :href="item.replicationView">{{
            item.component
          }}</gl-link>
          <span v-else>{{ item.component }}</span>
        </div>
        <div class="gl-mr-5" data-testid="sync-status">
          <geo-site-progress-bar
            v-if="item.syncValues"
            :title="
              /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ sprintf(
                $options.i18n.progressBarSyncTitle,
                { component: item.component },
              ) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
            "
            :target="`sync-progress-${siteId}-${item.component}`"
            :values="item.syncValues"
          />
          <span v-else class="gl-text-gray-400 gl-font-sm">{{ $options.i18n.nA }}</span>
        </div>
        <div data-testid="verification-status">
          <geo-site-progress-bar
            v-if="item.verificationValues"
            :title="
              /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ sprintf(
                $options.i18n.progressBarVerifTitle,
                { component: item.component },
              ) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
            "
            :target="`verification-progress-${siteId}-${item.component}`"
            :values="item.verificationValues"
            :success-label="$options.i18n.verified"
            :unavailable-label="$options.i18n.nothingToVerify"
          />
          <span v-else class="gl-text-gray-400 gl-font-sm">{{ $options.i18n.nA }}</span>
        </div>
      </slot>
    </div>
  </div>
</template>
