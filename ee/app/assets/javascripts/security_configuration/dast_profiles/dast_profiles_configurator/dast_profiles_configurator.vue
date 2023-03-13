<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import ProfileConflictAlert from 'ee/on_demand_scans_form/components/profile_selector/profile_conflict_alert.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { TYPENAME_SCANNER_PROFILE, TYPENAME_SITE_PROFILE } from '~/graphql_shared/constants';
import DastProfilesDrawer from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer.vue';
import ScannerProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_selector.vue';
import dastProfileConfiguratorMixin from 'ee/security_configuration/dast_profiles/dast_profiles_configurator_mixin';
import { DAST_SITE_VALIDATION_STATUS } from 'ee/security_configuration/dast_site_validation/constants';
import { SCAN_TYPE } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import {
  DAST_CONFIGURATION_HELP_PATH,
  SCANNER_TYPE,
  SITE_TYPE,
  DRAWER_VIEW_MODE,
} from 'ee/on_demand_scans/constants';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import { ERROR_MESSAGES } from 'ee/on_demand_scans_form/settings';

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
    ProfileConflictAlert,
  },
  mixins: [dastProfileConfiguratorMixin()],
  props: {
    configurationHeader: {
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
      activeProfile: undefined,
    };
  },
  computed: {
    errorMessage() {
      return ERROR_MESSAGES[this.errorType] || null;
    },
    profileIdInUse() {
      return this.isScannerProfile ? this.savedScannerProfileId : this.savedSiteProfileId;
    },
    selectedProfileId() {
      return this.isScannerProfile ? this.selectedScannerProfileId : this.selectedSiteProfileId;
    },
    libraryLink() {
      return this.isScannerProfile ? this.scannerProfilesLibraryPath : this.siteProfilesLibraryPath;
    },
    areProfilesSelected() {
      const { selectedScannerProfileId, selectedSiteProfileId } = this;
      return selectedScannerProfileId && selectedSiteProfileId;
    },
    isActiveScannerProfile() {
      return this.selectedScannerProfile?.scanType === SCAN_TYPE.ACTIVE;
    },
    isValidatedSiteProfile() {
      return this.selectedSiteProfile?.validationStatus === DAST_SITE_VALIDATION_STATUS.PASSED;
    },
    hasProfilesConflict() {
      return (
        this.areProfilesSelected && this.isActiveScannerProfile && !this.isValidatedSiteProfile
      );
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
      ? convertToGraphQLId(TYPENAME_SITE_PROFILE, params.site_profile_id)
      : this.selectedSiteProfileId;
    this.selectedScannerProfileId = params.scanner_profile_id
      ? convertToGraphQLId(TYPENAME_SCANNER_PROFILE, params.scanner_profile_id)
      : this.selectedScannerProfileId;
  },
  methods: {
    enableEditingMode({ profileType }) {
      this.resetActiveProfile();

      this.$nextTick(() => {
        this.selectActiveProfile(profileType);
        this.openProfileDrawer({ profileType, mode: DRAWER_VIEW_MODE.EDITING_MODE });
      });
    },
    selectActiveProfile(type) {
      this.activeProfile =
        type === SCANNER_TYPE ? this.selectedScannerProfile : this.selectedSiteProfile;
    },
    updateProfiles() {
      this.$emit('profiles-selected', {
        scannerProfile: this.selectedScannerProfile,
        siteProfile: this.selectedSiteProfile,
      });
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

        <profile-conflict-alert
          v-if="hasProfilesConflict"
          class="gl-my-5"
          data-testid="dast-profiles-conflict-alert"
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
