<script>
import { isEmpty } from 'lodash';
import { SCANNER_TYPE } from 'ee/on_demand_scans/constants';
import DastScannerProfileForm from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/components/dast_scanner_profile_form.vue';
import DastSiteProfileForm from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_profile_form.vue';
import dastProfilesDrawerMixin from './dast_profiles_drawer_mixin';

export default {
  name: 'DastProfilesDrawerForm',
  components: {
    DastScannerProfileForm,
    DastSiteProfileForm,
  },

  mixins: [dastProfilesDrawerMixin()],
  inject: ['projectPath'],
  props: {
    isProfileInUse: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    formComponent() {
      return this.profileType === SCANNER_TYPE ? DastScannerProfileForm : DastSiteProfileForm;
    },
    successEvent() {
      return isEmpty(this.profile) ? 'created' : 'edited';
    },
  },
  methods: {
    onSuccess(profileId) {
      this.$emit(this.successEvent, profileId);
    },
  },
};
</script>

<template>
  <component
    :is="formComponent"
    :stacked="true"
    :profile="profile"
    :is-profile-in-use="isProfileInUse"
    :project-full-path="projectPath"
    @success="onSuccess"
    v-on="$listeners"
  />
</template>
