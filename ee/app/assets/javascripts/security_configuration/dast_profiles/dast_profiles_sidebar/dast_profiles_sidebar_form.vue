<script>
import { SCANNER_TYPE, SITE_TYPE } from 'ee/on_demand_scans/constants';
import DastScannerProfileForm from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/components/dast_scanner_profile_form.vue';
import DastSiteProfileForm from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_profile_form.vue';
import dastProfilesSidebarMixin from './dast_profiles_sidebar_mixin';

export default {
  name: 'DastProfilesSidebarForm',
  components: {
    DastScannerProfileForm,
    DastSiteProfileForm,
  },
  mixins: [dastProfilesSidebarMixin()],
  inject: ['projectPath'],
  computed: {
    isScannerType() {
      return this.profileType === SCANNER_TYPE;
    },
    isSiteType() {
      return this.profileType === SITE_TYPE;
    },
  },
};
</script>

<template>
  <div>
    <dast-scanner-profile-form
      v-if="isScannerType"
      :stacked="true"
      :profile="profile"
      :project-full-path="projectPath"
      v-on="$listeners"
    />
    <dast-site-profile-form
      v-else-if="isSiteType"
      :stacked="true"
      :profile="profile"
      :project-full-path="projectPath"
      v-on="$listeners"
    />
  </div>
</template>
