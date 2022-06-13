<script>
import { GlCard, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { SCAN_TYPE } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import { DAST_SITE_VALIDATION_STATUS } from 'ee/security_configuration/dast_site_validation/constants';
import { TYPE_SCANNER_PROFILE, TYPE_SITE_PROFILE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { ERROR_MESSAGES, SCANNER_PROFILES_QUERY, SITE_PROFILES_QUERY } from '../../settings';
import ProfileConflictAlert from './profile_conflict_alert.vue';
import ScannerProfileSelector from './scanner_profile_selector.vue';
import SiteProfileSelector from './site_profile_selector.vue';

const createProfilesApolloOptions = (name, field, { fetchQuery, fetchError }) => ({
  query: fetchQuery,
  variables() {
    return {
      fullPath: this.fullPath,
    };
  },
  update(data) {
    const nodes = data?.project?.[name]?.nodes ?? [];
    if (nodes.length === 1) {
      this[field] = nodes[0].id;
    }
    return nodes;
  },
  error(e) {
    Sentry.captureException(e);
    this.$emit('error', ERROR_MESSAGES[fetchError]);
  },
});

export default {
  name: 'DastProfilesSelector',
  components: {
    GlCard,
    GlSkeletonLoader,
    ProfileConflictAlert,
    ScannerProfileSelector,
    SiteProfileSelector,
  },
  inject: ['fullPath'],
  apollo: {
    scannerProfiles: createProfilesApolloOptions(
      'scannerProfiles',
      'selectedScannerProfileId',
      SCANNER_PROFILES_QUERY,
    ),
    siteProfiles: createProfilesApolloOptions(
      'siteProfiles',
      'selectedSiteProfileId',
      SITE_PROFILES_QUERY,
    ),
  },
  data() {
    return {
      scannerProfiles: [],
      siteProfiles: [],
      selectedScannerProfileId: null,
      selectedSiteProfileId: null,
      errorType: null,
      errors: [],
    };
  },
  computed: {
    selectedScannerProfile() {
      return this.selectedScannerProfileId
        ? this.scannerProfiles.find(({ id }) => id === this.selectedScannerProfileId)
        : null;
    },
    selectedSiteProfile() {
      return this.selectedSiteProfileId
        ? this.siteProfiles.find(({ id }) => id === this.selectedSiteProfileId)
        : null;
    },
    isActiveScannerProfile() {
      return this.selectedScannerProfile?.scanType === SCAN_TYPE.ACTIVE;
    },
    isNonValidatedSiteProfile() {
      return (
        this.selectedSiteProfile &&
        this.selectedSiteProfile.validationStatus !== DAST_SITE_VALIDATION_STATUS.PASSED
      );
    },
    hasProfilesConflict() {
      return this.isActiveScannerProfile && this.isNonValidatedSiteProfile;
    },
    isLoadingProfiles() {
      return ['scannerProfiles', 'siteProfiles'].some((name) => this.$apollo.queries[name].loading);
    },
  },
  watch: {
    selectedScannerProfileId: 'updateProfiles',
    selectedSiteProfileId: 'updateProfiles',
    hasProfilesConflict: 'updateConflictingProfiles',
  },
  created() {
    const params = queryToObject(window.location.search, { legacySpacesDecode: true });

    this.selectedSiteProfileId = params.site_profile_id
      ? convertToGraphQLId(TYPE_SITE_PROFILE, params.site_profile_id)
      : this.selectedSiteProfileId;
    this.selectedScannerProfileId = params.scanner_profile_id
      ? convertToGraphQLId(TYPE_SCANNER_PROFILE, params.scanner_profile_id)
      : this.selectedScannerProfileId;
  },
  methods: {
    updateProfiles() {
      this.$emit('profiles-selected', {
        scannerProfile: this.selectedScannerProfile,
        siteProfile: this.selectedSiteProfile,
      });
    },
    updateConflictingProfiles(hasProfilesConflict) {
      this.$emit('profiles-has-conflict', hasProfilesConflict);
    },
  },
};
</script>

<template>
  <div data-test-id="dast-profiles-selector">
    <template v-if="isLoadingProfiles">
      <gl-card v-for="i in 2" :key="i" class="gl-mb-5">
        <template #header>
          <gl-skeleton-loader :width="1248" :height="15">
            <rect x="0" y="0" width="300" height="15" rx="4" />
          </gl-skeleton-loader>
        </template>
        <gl-skeleton-loader :width="1248" :height="15">
          <rect x="0" y="0" width="600" height="15" rx="4" />
        </gl-skeleton-loader>
        <gl-skeleton-loader :width="1248" :height="15">
          <rect x="0" y="0" width="300" height="15" rx="4" />
        </gl-skeleton-loader>
      </gl-card>
    </template>
    <template v-else>
      <scanner-profile-selector
        v-model="selectedScannerProfileId"
        class="gl-mb-5"
        :profiles="scannerProfiles"
        :selected-profile="selectedScannerProfile"
        :has-conflict="hasProfilesConflict"
      />

      <site-profile-selector
        v-model="selectedSiteProfileId"
        class="gl-mb-5"
        :profiles="siteProfiles"
        :selected-profile="selectedSiteProfile"
        :has-conflict="hasProfilesConflict"
      />

      <profile-conflict-alert
        v-if="hasProfilesConflict"
        class="gl-mb-5"
        data-testid="dast-profiles-conflict-alert"
      />
    </template>
  </div>
</template>
