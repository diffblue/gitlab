<script>
import { GlLink, GlSkeletonLoader, GlBadge, GlFriendlyWrap } from '@gitlab/ui';
import { LICENSE_APPROVAL_CLASSIFICATION } from 'ee/vue_shared/license_compliance/constants';
import LicenseComponentLinks from './license_component_links.vue';

export default {
  name: 'LicensesTableRow',
  components: {
    LicenseComponentLinks,
    GlLink,
    GlSkeletonLoader,
    GlBadge,
    GlFriendlyWrap,
  },
  props: {
    license: {
      type: Object,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    isDenied() {
      return this.license.classification === LICENSE_APPROVAL_CLASSIFICATION.DENIED;
    },
    nameIsLink() {
      return this.license.name.includes('http');
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row flex-md-column align-items-md-stretch px-2">
    <gl-skeleton-loader v-if="isLoading" :lines="1" />

    <div
      v-else
      class="d-md-flex align-items-baseline js-license-row"
      :data-spdx-id="license.spdx_identifier"
    >
      <!-- Name-->
      <div class="table-section section-30 section-wrap pr-md-3">
        <div class="table-mobile-header" role="rowheader">
          {{ s__('Licenses|Name') }}
        </div>
        <div class="table-mobile-content">
          <gl-link v-if="license.url" :href="license.url" target="_blank">{{
            license.name
          }}</gl-link>

          <gl-link v-else-if="nameIsLink" :href="license.name" target="_blank">
            <gl-friendly-wrap :text="license.name" />
          </gl-link>

          <template v-else>
            {{ license.name }}
          </template>
        </div>
      </div>

      <!-- Component -->
      <div class="table-section section-70 section-wrap pr-md-3">
        <div class="table-mobile-header" role="rowheader">{{ s__('Licenses|Component') }}</div>
        <div class="table-mobile-content d-md-flex justify-content-between align-items-center">
          <license-component-links :components="license.components" :title="license.name" />
          <div v-if="isDenied" class="d-inline-block">
            <gl-badge variant="warning" icon="warning">
              {{ s__('Licenses|Policy violation: denied') }}
            </gl-badge>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
