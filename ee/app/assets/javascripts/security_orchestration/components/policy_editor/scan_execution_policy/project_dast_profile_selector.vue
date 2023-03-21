<script>
import { GlButton, GlSprintf, GlTruncate } from '@gitlab/ui';
import DastProfilesDrawer from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer.vue';
import { s__ } from '~/locale';
import dastProfileConfiguratorMixin from 'ee/security_configuration/dast_profiles/dast_profiles_configurator_mixin';
import { SCANNER_TYPE, SITE_TYPE, DRAWER_VIEW_MODE } from 'ee/on_demand_scans/constants';
import { CONTENT_WRAPPER_CONTAINER_CLASS } from './constants';

export default {
  CONTENT_WRAPPER_CONTAINER_CLASS,
  SITE_TYPE,
  SCANNER_TYPE,
  DRAWER_VIEW_MODE,
  i18n: {
    scannerButtonText: s__('ScanExecutionPolicy|Select scanner profile'),
    siteButtonText: s__('ScanExecutionPolicy|Select site profile'),
    dastProfilesMessage: s__(
      'ScanExecutionPolicy|scanner profile %{scannerProfile} and site profile %{siteProfile}',
    ),
  },
  name: 'ProjectDastProfileSelector',
  components: {
    GlButton,
    GlSprintf,
    GlTruncate,
    DastProfilesDrawer,
  },
  mixins: [dastProfileConfiguratorMixin()],
  provide() {
    return {
      projectPath: this.fullPath,
    };
  },
  data() {
    return {
      activeProfile: undefined,
      isSideDrawerOpen: false,
      selectedScannerProfileId: null,
      selectedSiteProfileId: null,
    };
  },
  computed: {
    scannerProfileButtonText() {
      return this.selectedScannerProfile?.profileName || this.$options.i18n.scannerButtonText;
    },
    siteProfileButtonText() {
      return this.selectedSiteProfile?.profileName || this.$options.i18n.siteButtonText;
    },
    profileIdInUse() {
      return this.isScannerProfile ? this.savedScannerProfileId : this.savedSiteProfileId;
    },
    selectedProfileId() {
      return this.isScannerProfile ? this.selectedScannerProfileId : this.selectedSiteProfileId;
    },
  },
  watch: {
    selectedScannerProfile: 'updateProfiles',
    selectedSiteProfile: 'updateProfiles',
  },
  mounted() {
    if (
      this.savedScannerProfileName &&
      !this.doesProfileExist(this.scannerProfiles, this.savedScannerProfileName)
    ) {
      this.$emit('error');
    }

    if (
      this.savedSiteProfileName &&
      !this.doesProfileExist(this.siteProfiles, this.savedSiteProfileName)
    ) {
      this.$emit('error');
    }
  },
  methods: {
    doesProfileExist(profiles = [], savedProfileName) {
      return profiles.some(({ profileName }) => profileName === savedProfileName);
    },
    updateProfiles() {
      this.$emit('profiles-selected', {
        scannerProfile: this.selectedScannerProfile?.profileName,
        siteProfile: this.selectedSiteProfile?.profileName,
      });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <gl-sprintf :message="$options.i18n.dastProfilesMessage">
      <template #scannerProfile>
        <gl-button
          data-testid="scanner-profile-trigger"
          :disabled="failedToLoadProfiles"
          :loading="isLoadingProfiles"
          @click="
            openProfileDrawer({
              profileType: $options.SCANNER_TYPE,
              mode: $options.DRAWER_VIEW_MODE.READING_MODE,
            })
          "
        >
          <gl-truncate :text="scannerProfileButtonText" />
        </gl-button>
      </template>
      <template #siteProfile>
        <gl-button
          data-testid="site-profile-trigger"
          :disabled="failedToLoadProfiles"
          :loading="isLoadingProfiles"
          @click="
            openProfileDrawer({
              profileType: $options.SITE_TYPE,
              mode: $options.DRAWER_VIEW_MODE.READING_MODE,
            })
          "
        >
          <gl-truncate :text="siteProfileButtonText" />
        </gl-button>
      </template>
    </gl-sprintf>

    <dast-profiles-drawer
      :active-profile="activeProfile"
      :container-class="$options.CONTENT_WRAPPER_CONTAINER_CLASS"
      :open="isSideDrawerOpen"
      :is-loading="isLoadingProfiles"
      :profiles="selectedProfiles"
      :profile-id-in-use="profileIdInUse"
      :selected-profile-id="selectedProfileId"
      @close-drawer="closeProfileDrawer"
      @reopen-drawer="reopenProfileDrawer"
      @select-profile="selectProfile"
      @profile-submitted="onScannerProfileCreated"
    />
  </div>
</template>
