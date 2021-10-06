<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ProfileSelector from './profile_selector.vue';
import SiteProfileSummary from './site_profile_summary.vue';

export default {
  name: 'OnDemandScansSiteProfileSelector',
  components: {
    ProfileSelector,
    SiteProfileSummary,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    siteProfilesLibraryPath: {
      default: '',
    },
    newSiteProfilePath: {
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
          dropdownLabel: `${profile.profileName}: ${profile.targetUrl}`,
        };
      });
    },
  },
};
</script>

<template>
  <profile-selector
    :library-path="siteProfilesLibraryPath"
    :new-profile-path="newSiteProfilePath"
    :profiles="formattedProfiles"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #title>{{ s__('OnDemandScans|Site profile') }}</template>
    <template #label>{{ s__('OnDemandScans|Use existing site profile') }}</template>
    <template #no-profiles>{{
      s__(
        'OnDemandScans|No profile yet. In order to create a new scan, you need to have at least one completed site profile.',
      )
    }}</template>
    <template #new-profile>{{ s__('OnDemandScans|Create new site profile') }}</template>
    <template #manage-profile>{{ s__('OnDemandScans|Manage site profiles') }}</template>
    <template #summary>
      <site-profile-summary
        v-if="selectedProfile"
        :profile="selectedProfile"
        :has-conflict="hasConflict"
      />
    </template>
  </profile-selector>
</template>
