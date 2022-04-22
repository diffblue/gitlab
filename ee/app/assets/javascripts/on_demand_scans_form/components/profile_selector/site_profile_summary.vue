<script>
import {
  EXCLUDED_URLS_SEPARATOR,
  TARGET_TYPES,
} from 'ee/security_configuration/dast_profiles/dast_site_profiles/constants';
import { DAST_SITE_VALIDATION_STATUS } from 'ee/security_configuration/dast_site_validation/constants';
import { s__ } from '~/locale';
import SummaryCell from './summary_cell.vue';

export default {
  name: 'DastSiteProfileSummary',
  components: {
    SummaryCell,
  },
  props: {
    profile: {
      type: Object,
      required: true,
    },
    hasConflict: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    i18n() {
      return {
        targetUrl: this.isTargetAPI
          ? s__('DastProfiles|API endpoint URL')
          : s__('DastProfiles|Target URL'),
        targetType: s__('DastProfiles|Site type'),
        authUrl: s__('DastProfiles|Authentication URL'),
        username: s__('DastProfiles|Username'),
        password: s__('DastProfiles|Password'),
        usernameField: s__('DastProfiles|Username form field'),
        passwordField: s__('DastProfiles|Password form field'),
        submitField: s__('DastProfiles|Submit button'),
        excludedUrls: this.isTargetAPI
          ? s__('DastProfiles|Excluded paths')
          : s__('DastProfiles|Excluded URLs'),
        requestHeaders: s__('DastProfiles|Request headers'),
        validationStatus: s__('DastProfiles|Validation status'),
      };
    },
    hasExcludedUrls() {
      return this.profile.excludedUrls?.length > 0;
    },
    displayExcludedUrls() {
      return this.hasExcludedUrls
        ? this.profile.excludedUrls.join(this.$options.EXCLUDED_URLS_SEPARATOR)
        : undefined;
    },
    targetTypeValue() {
      return TARGET_TYPES[this.profile.targetType].text;
    },
    isTargetAPI() {
      return this.profile.targetType === TARGET_TYPES.API.value;
    },
    isProfileValidated() {
      return this.profile.validationStatus === DAST_SITE_VALIDATION_STATUS.PASSED
        ? s__('DastProfiles|Validated')
        : s__('DastProfiles|Not Validated');
    },
  },
  EXCLUDED_URLS_SEPARATOR,
};
</script>

<template>
  <div class="row">
    <summary-cell
      :class="{ 'gl-text-red-500': hasConflict }"
      :label="i18n.targetUrl"
      :value="profile.targetUrl"
    />
    <summary-cell :label="i18n.targetType" :value="targetTypeValue" />
    <template v-if="profile.auth.enabled">
      <summary-cell :label="i18n.authUrl" :value="profile.auth.url" />
      <summary-cell :label="i18n.username" :value="profile.auth.username" />
      <summary-cell :label="i18n.password" value="••••••••" />
      <summary-cell :label="i18n.usernameField" :value="profile.auth.usernameField" />
      <summary-cell :label="i18n.passwordField" :value="profile.auth.passwordField" />
      <summary-cell :label="i18n.submitField" :value="profile.auth.submitField" />
    </template>
    <summary-cell :label="i18n.excludedUrls" :value="displayExcludedUrls" />
    <summary-cell
      :label="i18n.requestHeaders"
      :value="profile.requestHeaders ? __('[Redacted]') : undefined"
    />
    <summary-cell :label="i18n.validationStatus" :value="isProfileValidated" />
  </div>
</template>
