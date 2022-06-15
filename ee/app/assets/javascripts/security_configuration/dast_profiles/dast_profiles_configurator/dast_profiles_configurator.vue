<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { TYPE_SCANNER_PROFILE, TYPE_SITE_PROFILE } from '~/graphql_shared/constants';
import DastProfilesSidebar from 'ee/security_configuration/dast_profiles/dast_profiles_sidebar/dast_profiles_sidebar.vue';
import ScannerProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_selector.vue';
import {
  DAST_CONFIGURATION_HELP_PATH,
  SCANNER_TYPE,
  SITE_TYPE,
} from 'ee/on_demand_scans/constants';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import {
  ERROR_MESSAGES,
  ERROR_FETCH_SCANNER_PROFILES,
  ERROR_FETCH_SITE_PROFILES,
  SCANNER_PROFILES_QUERY,
  SITE_PROFILES_QUERY,
} from 'ee/on_demand_scans_form/settings';

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
    this.errorType = fetchError;
  },
});

export default {
  SCANNER_TYPE,
  SITE_TYPE,
  dastConfigurationHelpPath: DAST_CONFIGURATION_HELP_PATH,
  name: 'DastProfilesConfigurator',
  i18n: {
    dastConfigurationHeader: s__('OnDemandScans|DAST configuration'),
    dastConfigurationDescription: s__(
      "OnDemandScans|DAST scans for vulnerabilities in your project's running application, website, or API.  For details of all configuration options, see the %{linkStart}GitLab DAST documentation%{linkEnd}.",
    ),
  },
  components: {
    GlLink,
    GlSprintf,
    DastProfilesSidebar,
    ScannerProfileSelector,
    SiteProfileSelector,
    SectionLayout,
  },
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
  props: {
    configurationHeader: {
      type: String,
      required: false,
      default: '',
    },
    savedProfiles: {
      type: Object,
      required: false,
      default: null,
    },
    fullPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      scannerProfiles: [],
      siteProfiles: [],
      errorType: null,
      isSideDrawerOpen: false,
      profileType: '',
      activeProfile: {},
      selectedScannerProfileId: this.savedProfiles?.dastScannerProfile.id || null,
      selectedSiteProfileId: this.savedProfiles?.dastSiteProfile.id || null,
    };
  },
  computed: {
    errorMessage() {
      return ERROR_MESSAGES[this.errorType] || null;
    },
    failedToLoadProfiles() {
      return [ERROR_FETCH_SCANNER_PROFILES, ERROR_FETCH_SITE_PROFILES].includes(this.errorType);
    },
    isLoadingProfiles() {
      return ['scannerProfiles', 'siteProfiles'].some((name) => this.$apollo.queries[name].loading);
    },
    profileIdInUse() {
      return this.profileType === SCANNER_TYPE
        ? this.savedScannerProfileId
        : this.savedSiteProfileId;
    },
    savedScannerProfileId() {
      return this.savedProfiles?.dastScannerProfile.id;
    },
    savedSiteProfileId() {
      return this.savedProfiles?.dastSiteProfile.id;
    },
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
    selectedProfileId() {
      return this.profileType === SCANNER_TYPE
        ? this.selectedScannerProfileId
        : this.selectedSiteProfileId;
    },
    selectedProfiles() {
      return this.profileType === SCANNER_TYPE ? this.scannerProfiles : this.siteProfiles;
    },
  },
  watch: {
    selectedScannerProfile: 'updateProfiles',
    selectedSiteProfile: 'updateProfiles',
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
    enableEditingMode(type) {
      this.selectActiveProfile(type);
      this.openProfileDrawer(type);
    },
    openProfileDrawer(type) {
      this.isSideDrawerOpen = false;
      this.profileType = type;
      this.$nextTick(() => {
        this.isSideDrawerOpen = true;
      });
    },
    closeProfileDrawer() {
      this.isSideDrawerOpen = false;
      this.activeProfile = {};
    },
    selectActiveProfile(type) {
      this.activeProfile =
        type === SCANNER_TYPE ? this.selectedScannerProfile : this.selectedSiteProfile;
    },
    selectProfile(payload) {
      this.updateProfileFromSelector(payload);
      this.closeProfileDrawer();
    },
    isNewProfile(id) {
      return this.selectedProfiles.every((profile) => profile.id !== id);
    },
    updateProfiles() {
      this.$emit('profiles-selected', {
        scannerProfile: this.selectedScannerProfile,
        siteProfile: this.selectedSiteProfile,
      });
    },
    updateProfileFromSelector({ profile: { id }, profileType }) {
      if (profileType === SCANNER_TYPE) {
        this.selectedScannerProfileId = id;
      } else {
        this.selectedSiteProfileId = id;
      }
      this.closeProfileDrawer();
    },
    onScannerProfileCreated({ profile, profileType }) {
      /**
       * TODO remove refetch method
       * after feature is complete
       * substitute with cache update flow
       */
      if (this.isNewProfile(profile.id)) {
        this.updateProfileFromSelector({ profile, profileType });
      }

      const type = `${profileType}Profiles`;
      this.$apollo.queries[type].refetch();
    },
  },
};
</script>

<template>
  <div>
    <section-layout
      v-if="!failedToLoadProfiles"
      :heading="configurationHeader || $options.i18n.dastConfigurationHeader"
      :is-loading="isLoadingProfiles"
    >
      <template #description>
        <slot name="description">
          <gl-sprintf :message="$options.i18n.dastConfigurationDescription">
            <template #link="{ content }">
              <gl-link :href="$options.dastConfigurationHelpPath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </slot>
      </template>
      <template #features>
        <scanner-profile-selector
          class="gl-mb-6"
          :selected-profile="selectedScannerProfile"
          :profile-id-in-use="savedScannerProfileId"
          @open-drawer="openProfileDrawer($options.SCANNER_TYPE)"
          @edit="enableEditingMode($options.SCANNER_TYPE)"
        />

        <site-profile-selector
          class="gl-mb-2"
          :selected-profile="selectedSiteProfile"
          :profile-id-in-use="savedSiteProfileId"
          @open-drawer="openProfileDrawer($options.SITE_TYPE)"
          @edit="enableEditingMode($options.SITE_TYPE)"
        />
      </template>
    </section-layout>

    <dast-profiles-sidebar
      :profiles="selectedProfiles"
      :profile-id-in-use="profileIdInUse"
      :active-profile="activeProfile"
      :profile-type="profileType"
      :is-open="isSideDrawerOpen"
      :is-loading="isLoadingProfiles"
      :selected-profile-id="selectedProfileId"
      @close-drawer="closeProfileDrawer"
      @reopen-drawer="openProfileDrawer"
      @select-profile="selectProfile"
      @profile-submitted="onScannerProfileCreated"
    />
  </div>
</template>
