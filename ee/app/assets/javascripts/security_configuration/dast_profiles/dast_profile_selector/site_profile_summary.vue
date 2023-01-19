<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import DastSiteValidationBadge from 'ee/security_configuration/dast_profiles/components/dast_site_validation_badge.vue';
import DastSiteValidationModal from 'ee/security_configuration/dast_site_validation/components/dast_site_validation_modal.vue';
import {
  DAST_SITE_VALIDATION_STATUS,
  DAST_SITE_VALIDATION_MODAL_ID,
} from 'ee/security_configuration/dast_site_validation/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  EXCLUDED_URLS_SEPARATOR,
  TARGET_TYPES,
  SCAN_METHODS,
} from 'ee/security_configuration/dast_profiles/dast_site_profiles/constants';
import { SITE_TYPE } from 'ee/on_demand_scans/constants';
import { s__ } from '~/locale';
import DastProfileSummaryCard from './dast_profile_summary_card.vue';
import SummaryCell from './summary_cell.vue';

export default {
  SITE_TYPE,
  name: 'DastSiteProfileSummary',
  dastSiteValidationModalId: DAST_SITE_VALIDATION_MODAL_ID,
  components: {
    DastProfileSummaryCard,
    SummaryCell,
    DastSiteValidationBadge,
    GlButton,
    DastSiteValidationModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['projectPath'],
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
  data() {
    return {
      validateTargetUrl: null,
    };
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
        scanMethod: s__('DastProfiles|Scan Method'),
        validateProfileTooltip: s__('DastProfiles|Validate site profile'),
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
    selectedScanMethod() {
      return SCAN_METHODS[this.profile.scanMethod];
    },
    hasScanMethod() {
      return Boolean(this.selectedScanMethod);
    },
  },
  methods: {
    validateUrl(url) {
      this.validateTargetUrl = url;
      this.$nextTick(() => {
        this.$refs[DAST_SITE_VALIDATION_MODAL_ID].show();
      });
    },
    showValidatebutton(status) {
      const { NONE, FAILED } = DAST_SITE_VALIDATION_STATUS;
      return this.glFeatures.dastSiteValidationDrawer && [NONE, FAILED].includes(status);
    },
    validateButtonLabel(status) {
      return status === DAST_SITE_VALIDATION_STATUS.NONE
        ? s__('DastProfiles|Validate')
        : s__('DastProfiles|Retry');
    },
  },
  EXCLUDED_URLS_SEPARATOR,
};
</script>

<template>
  <dast-profile-summary-card :profile-type="$options.SITE_TYPE" v-bind="$attrs" v-on="$listeners">
    <template #title>
      {{ profile.profileName }}
    </template>
    <template #summary>
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
      <summary-cell :label="i18n.validationStatus">
        <dast-site-validation-badge :status="profile.validationStatus" />
        <gl-button
          v-if="showValidatebutton(profile.validationStatus)"
          v-gl-tooltip.hover
          :title="i18n.validateProfileTooltip"
          class="gl-ml-2"
          variant="link"
          @click="validateUrl(profile.targetUrl)"
          >{{ validateButtonLabel(profile.validationStatus) }}</gl-button
        >
        <dast-site-validation-modal
          v-if="glFeatures.dastSiteValidationDrawer && validateTargetUrl"
          :ref="$options.dastSiteValidationModalId"
          :full-path="projectPath"
          :target-url="validateTargetUrl"
          @hidden="validateTargetUrl = null"
        />
      </summary-cell>
      <summary-cell
        v-if="hasScanMethod"
        :label="i18n.scanMethod"
        :value="selectedScanMethod.text"
      />
      <summary-cell
        v-if="hasScanMethod"
        :label="selectedScanMethod.inputLabel"
        :value="profile.scanFilePath"
      />
    </template>
  </dast-profile-summary-card>
</template>
