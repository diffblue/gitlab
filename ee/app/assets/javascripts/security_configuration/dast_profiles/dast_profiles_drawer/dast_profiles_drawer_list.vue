<script>
import { SCANNER_TYPE } from 'ee/on_demand_scans/constants';
import ScannerProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';
import SiteProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import dastProfilesDrawerMixin from './dast_profiles_drawer_mixin';

export default {
  name: 'DastProfilesDrawerList',
  components: {
    ScannerProfileSummary,
    SiteProfileSummary,
  },
  mixins: [dastProfilesDrawerMixin()],
  props: {
    profiles: {
      type: Array,
      required: false,
      default: () => [],
    },
    profileIdInUse: {
      type: String,
      required: false,
      default: null,
    },
    selectedProfileId: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    summaryComponent() {
      return this.profileType === SCANNER_TYPE ? ScannerProfileSummary : SiteProfileSummary;
    },
  },
  methods: {
    isProfileInUse(profile) {
      return profile.id === this.profileIdInUse;
    },
    isProfileSelected(profile) {
      return profile.id === this.selectedProfileId;
    },
  },
};
</script>

<template>
  <div data-testid="dast-profiles-drawer list">
    <component
      :is="summaryComponent"
      v-for="profile in profiles"
      :key="profile.id"
      :profile="profile"
      :is-profile-in-use="isProfileInUse(profile)"
      :is-profile-selected="isProfileSelected(profile)"
      :allow-selection="true"
      @edit="$emit('edit', profile)"
      @select-profile="$emit('select-profile', { profile, profileType })"
    />
  </div>
</template>
