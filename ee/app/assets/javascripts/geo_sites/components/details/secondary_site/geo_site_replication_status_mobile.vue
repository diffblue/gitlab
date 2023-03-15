<script>
import GeoSiteProgressBar from 'ee/geo_sites/components/details/geo_site_progress_bar.vue';

export default {
  name: 'GeoSiteReplicationStatusMobile',
  components: {
    GeoSiteProgressBar,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    translations: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-5 gl-display-flex gl-flex-direction-column" data-testid="sync-status">
      <span class="gl-font-sm gl-mb-3">{{ translations.syncStatus }}</span>
      <geo-site-progress-bar
        v-if="item.syncValues"
        :title="
          /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
          sprintf(translations.progressBarSyncTitle, {
            component: item.component,
          }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
        "
        :target="`mobile-sync-progress-${item.component}`"
        :values="item.syncValues"
      />
      <span v-else class="gl-text-gray-400 gl-font-sm">{{ translations.nA }}</span>
    </div>
    <div class="gl-display-flex gl-flex-direction-column" data-testid="verification-status">
      <span class="gl-font-sm gl-mb-3">{{ translations.verifStatus }}</span>
      <geo-site-progress-bar
        v-if="item.verificationValues"
        :title="
          /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
          sprintf(translations.progressBarVerifTitle, {
            component: item.component,
          }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
        "
        :target="`mobile-verification-progress-${item.component}`"
        :values="item.verificationValues"
        :success-label="translations.verified"
        :unavailable-label="translations.nothingToVerify"
      />
      <span v-else class="gl-text-gray-400 gl-font-sm">{{ translations.nA }}</span>
    </div>
  </div>
</template>
