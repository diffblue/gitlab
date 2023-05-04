<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import GeoSiteActions from './geo_site_actions.vue';
import GeoSiteHealthStatus from './geo_site_health_status.vue';
import GeoSiteLastUpdated from './geo_site_last_updated.vue';

export default {
  name: 'GeoSiteHeader',
  i18n: {
    expand: __('Expand'),
    collapse: __('Collapse'),
  },
  components: {
    GlButton,
    GeoSiteHealthStatus,
    GeoSiteLastUpdated,
    GeoSiteActions,
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    chevronIcon() {
      return this.collapsed ? 'chevron-right' : 'chevron-down';
    },
    chevronLabel() {
      return this.collapsed ? this.$options.i18n.expand : this.$options.i18n.collapse;
    },
    statusCheckTimestamp() {
      return this.site.lastSuccessfulStatusCheckTimestamp
        ? this.site.lastSuccessfulStatusCheckTimestamp * 1000 // Converting timestamp to ms
        : null;
    },
  },
};
</script>

<template>
  <div
    class="gl-display-grid geo-site-header-grid-columns gl-bg-gray-10 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100 gl-py-3 gl-px-5"
  >
    <div class="gl-display-flex gl-align-items-center">
      <gl-button
        class="gl-mr-3 gl-p-0!"
        category="tertiary"
        variant="confirm"
        :icon="chevronIcon"
        :aria-label="chevronLabel"
        @click="$emit('collapse')"
      />
      <div
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-md-align-items-center gl-flex-grow-1"
      >
        <div class="gl-display-flex gl-align-items-center gl-flex-grow-1 gl-flex-basis-0">
          <h4 class="gl-font-lg">{{ site.name }}</h4>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-flex-grow-2 gl-flex-basis-0">
          <geo-site-health-status :status="site.healthStatus" />
          <geo-site-last-updated
            v-if="statusCheckTimestamp"
            class="gl-ml-2"
            :status-check-timestamp="statusCheckTimestamp"
          />
        </div>
      </div>
    </div>
    <div class="gl-display-flex gl-align-items-center gl-justify-content-end">
      <geo-site-actions :site="site" />
    </div>
  </div>
</template>
