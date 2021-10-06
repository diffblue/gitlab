<script>
import ProfileSelector from './profile_selector.vue';
import ScannerProfileSummary from './scanner_profile_summary.vue';

export default {
  name: 'OnDemandScansScannerProfileSelector',
  components: {
    ProfileSelector,
    ScannerProfileSummary,
  },
  inject: {
    scannerProfilesLibraryPath: {
      default: '',
    },
    newScannerProfilePath: {
      default: '',
    },
  },
  props: {
    profiles: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedProfile: {
      type: Object,
      required: false,
      default: null,
    },
    hasConflict: {
      type: Boolean,
      required: false,
      default: null,
    },
  },
  computed: {
    formattedProfiles() {
      return this.profiles.map((profile) => {
        return {
          ...profile,
          dropdownLabel: profile.profileName,
        };
      });
    },
  },
};
</script>

<template>
  <profile-selector
    :library-path="scannerProfilesLibraryPath"
    :new-profile-path="newScannerProfilePath"
    :profiles="formattedProfiles"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #title>{{ s__('OnDemandScans|Scanner profile') }}</template>
    <template #label>{{ s__('OnDemandScans|Use existing scanner profile') }}</template>
    <template #no-profiles>{{
      s__(
        'OnDemandScans|No profile yet. In order to create a new scan, you need to have at least one completed scanner profile.',
      )
    }}</template>
    <template #new-profile>{{ s__('OnDemandScans|Create new scanner profile') }}</template>
    <template #manage-profile>{{ s__('OnDemandScans|Manage scanner profiles') }}</template>
    <template #summary>
      <scanner-profile-summary
        v-if="selectedProfile"
        :profile="selectedProfile"
        :has-conflict="hasConflict"
      />
    </template>
  </profile-selector>
</template>
