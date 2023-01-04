<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { TYPE_SCANNER_PROFILE, TYPE_SITE_PROFILE } from '~/graphql_shared/constants';
import DastProfilesDrawer from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer.vue';
import ScannerProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_selector.vue';
import dastProfileConfiguratorMixin from 'ee/security_configuration/dast_profiles/dast_profiles_configurator_mixin';
import {
  DAST_CONFIGURATION_HELP_PATH,
  SCANNER_TYPE,
  SITE_TYPE,
  DRAWER_VIEW_MODE,
} from 'ee/on_demand_scans/constants';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import {
  ERROR_MESSAGES,
  ERROR_FETCH_SCANNER_PROFILES,
  ERROR_FETCH_SITE_PROFILES,
  SCANNER_PROFILES_QUERY,
  SITE_PROFILES_QUERY,
} from 'ee/on_demand_scans_form/settings';

const createProfilesApolloOptions = (name, field, savedField, { fetchQuery, fetchError }) => ({
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

    if (this[savedField] && nodes.length > 1) {
      this[field] = this.findSavedProfileId(nodes, this[savedField]);
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
  DRAWER_VIEW_MODE,
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
    DastProfilesDrawer,
    ScannerProfileSelector,
    SiteProfileSelector,
    SectionLayout,
  },
  apollo: {
    scannerProfiles: createProfilesApolloOptions(
      'scannerProfiles',
      'selectedScannerProfileId',
      'savedScannerProfileName',
      SCANNER_PROFILES_QUERY,
    ),
    siteProfiles: createProfilesApolloOptions(
      'siteProfiles',
      'selectedSiteProfileId',
      'savedSiteProfileName',
      SITE_PROFILES_QUERY,
    ),
  },
  mixins: [dastProfileConfiguratorMixin()],
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
    savedScannerProfileName: {
      type: String,
      required: false,
      default: null,
    },
    savedSiteProfileName: {
      type: String,
      required: false,
      default: null,
    },
    fullPath: {
      type: String,
      required: false,
      default: '',
    },
    siteProfilesLibraryPath: {
      type: String,
      required: false,
      default: '',
    },
    scannerProfilesLibraryPath: {
      type: String,
      required: false,
      default: '',
    },
    open: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      scannerProfiles: [],
      siteProfiles: [],
      errorType: null,
      isSideDrawerOpen: false,
      activeProfile: undefined,
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
    isScannerProfile() {
      return this.profileType === SCANNER_TYPE;
    },
    profileIdInUse() {
      return this.isScannerProfile ? this.savedScannerProfileId : this.savedSiteProfileId;
    },
    savedScannerProfileId() {
      return this.savedScannerProfileName
        ? this.findSavedProfileId(this.scannerProfiles, this.savedScannerProfileName)
        : this.savedProfiles?.dastScannerProfile.id;
    },
    savedSiteProfileId() {
      return this.savedSiteProfileName
        ? this.findSavedProfileId(this.siteProfiles, this.savedSiteProfileName)
        : this.savedProfiles?.dastSiteProfile.id;
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
      return this.isScannerProfile ? this.selectedScannerProfileId : this.selectedSiteProfileId;
    },
    selectedProfiles() {
      return this.isScannerProfile ? this.scannerProfiles : this.siteProfiles;
    },
    libraryLink() {
      return this.isScannerProfile ? this.scannerProfilesLibraryPath : this.siteProfilesLibraryPath;
    },
  },
  watch: {
    selectedScannerProfile: 'updateProfiles',
    selectedSiteProfile: 'updateProfiles',
    open(newVal) {
      if (!newVal) {
        this.closeProfileDrawer();
      }
    },
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
    findSavedProfileId(profiles, name) {
      return profiles.find(({ profileName }) => name === profileName)?.id || null;
    },
    enableEditingMode({ profileType }) {
      this.resetActiveProfile();

      this.$nextTick(() => {
        this.selectActiveProfile(profileType);
        this.openProfileDrawer({ profileType, mode: DRAWER_VIEW_MODE.EDITING_MODE });
      });
    },
    reopenProfileDrawer() {
      this.isSideDrawerOpen = false;
      this.$nextTick(() => {
        this.isSideDrawerOpen = true;
      });
    },
    async openProfileDrawer({ profileType, mode }) {
      if (this.sharedData.formTouched) {
        this.toggleModal({ showModal: true });
        await this.setCachedPayload({ profileType, mode });

        return;
      }

      await this.goFirstStep({ profileType, mode });

      this.isSideDrawerOpen = false;
      this.$nextTick(() => {
        this.isSideDrawerOpen = true;
        this.$emit('open-drawer');
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
    async selectProfile(payload) {
      this.updateProfileFromSelector(payload);
      await this.goBack();

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
    resetActiveProfile() {
      this.activeProfile = undefined;
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
          @open-drawer="
            openProfileDrawer({
              profileType: $options.SCANNER_TYPE,
              mode: $options.DRAWER_VIEW_MODE.READING_MODE,
            })
          "
          @edit="
            enableEditingMode({
              profileType: $options.SCANNER_TYPE,
            })
          "
        />

        <site-profile-selector
          class="gl-mb-2"
          :selected-profile="selectedSiteProfile"
          :profile-id-in-use="savedSiteProfileId"
          @open-drawer="
            openProfileDrawer({
              profileType: $options.SITE_TYPE,
              mode: $options.DRAWER_VIEW_MODE.READING_MODE,
            })
          "
          @edit="
            enableEditingMode({
              profileType: $options.SITE_TYPE,
            })
          "
        />
      </template>
    </section-layout>

    <dast-profiles-drawer
      :profiles="selectedProfiles"
      :profile-id-in-use="profileIdInUse"
      :active-profile="activeProfile"
      :library-link="libraryLink"
      :open="isSideDrawerOpen"
      :is-loading="isLoadingProfiles"
      :selected-profile-id="selectedProfileId"
      @close-drawer="closeProfileDrawer"
      @reopen-drawer="reopenProfileDrawer"
      @select-profile="selectProfile"
      @profile-submitted="onScannerProfileCreated"
    />
  </div>
</template>
