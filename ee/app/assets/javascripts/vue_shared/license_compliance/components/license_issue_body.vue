<script>
import { mapActions } from 'vuex';
import { GlLink } from '@gitlab/ui';
import api from '~/api';

import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import { LICENSE_LINK_TELEMETRY_EVENT } from '../constants';
import LicensePackages from './license_packages.vue';

export default {
  name: 'LicenseIssueBody',
  components: { LicensePackages, GlLink },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasPackages() {
      return Boolean(this.issue.packages.length);
    },
  },
  methods: {
    ...mapActions(LICENSE_MANAGEMENT, ['setLicenseInModal']),
    trackLinkClick() {
      api.trackRedisHllUserEvent(LICENSE_LINK_TELEMETRY_EVENT);
      api.trackRedisCounterEvent(LICENSE_LINK_TELEMETRY_EVENT);
    },
  },
};
</script>

<template>
  <div class="report-block-info license-item">
    <gl-link v-if="issue.url" :href="issue.url" target="_blank" @click="trackLinkClick">{{
      issue.name
    }}</gl-link>
    <span v-else data-testid="license-copy">{{ issue.name }}</span>
    <license-packages v-if="hasPackages" :packages="issue.packages" class="text-secondary" />
  </div>
</template>
