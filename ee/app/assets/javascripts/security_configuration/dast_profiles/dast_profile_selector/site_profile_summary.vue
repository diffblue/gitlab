<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import DastSiteValidationBadge from 'ee/security_configuration/dast_profiles/components/dast_site_validation_badge.vue';
import DastSiteValidationModal from 'ee/security_configuration/dast_site_validation/components/dast_site_validation_modal.vue';
import {
  DAST_SITE_VALIDATION_STATUS,
  DAST_SITE_VALIDATION_MODAL_ID,
  DAST_SITE_VALIDATION_POLLING_INTERVAL,
  DAST_SITE_VALIDATION_ALLOWED_TIMELINE_IN_MINUTES,
} from 'ee/security_configuration/dast_site_validation/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  EXCLUDED_URLS_SEPARATOR,
  TARGET_TYPES,
  SCAN_METHODS,
} from 'ee/security_configuration/dast_profiles/dast_site_profiles/constants';
import { SITE_TYPE } from 'ee/on_demand_scans/constants';
import { s__ } from '~/locale';
import dastSiteValidationsQuery from 'ee/security_configuration/dast_site_validation/graphql/dast_site_validations.query.graphql';
import { fetchPolicies } from '~/lib/graphql';
import { updateSiteProfilesStatuses } from 'ee/security_configuration/dast_profiles/graphql/cache_utils';
import { getTimeDifferenceMinutes } from 'ee/security_configuration/utils';
import DastProfileSummaryCard from './dast_profile_summary_card.vue';
import SummaryCell from './summary_cell.vue';

const { NONE, PENDING, INPROGRESS, FAILED, PASSED } = DAST_SITE_VALIDATION_STATUS;

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
  apollo: {
    validations: {
      query: dastSiteValidationsQuery,
      fetchPolicy: fetchPolicies.NO_CACHE,
      manual: true,
      variables() {
        return {
          fullPath: this.projectPath,
          urls: this.urlsPendingValidation,
        };
      },
      pollInterval: DAST_SITE_VALIDATION_POLLING_INTERVAL,
      skip() {
        return !this.urlsPendingValidation.length;
      },
      result({
        data: {
          project: {
            validations: { nodes = [] },
          },
        },
      }) {
        nodes.forEach(({ normalizedTargetUrl, status, validationStartedAt }) => {
          this.updateSiteProfilesStatuses(normalizedTargetUrl, status, validationStartedAt);
        });
      },
    },
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
      return this.profile.validationStatus === PASSED
        ? s__('DastProfiles|Validated')
        : s__('DastProfiles|Not Validated');
    },
    selectedScanMethod() {
      return SCAN_METHODS[this.profile.scanMethod];
    },
    hasScanMethod() {
      return Boolean(this.selectedScanMethod);
    },
    urlsPendingValidation() {
      if (this.isPendingValidation(this.profile.validationStatus)) {
        return [this.profile.normalizedTargetUrl];
      }
      return [];
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
      return [NONE, FAILED].includes(status);
    },
    validateButtonLabel(status) {
      return status === DAST_SITE_VALIDATION_STATUS.NONE
        ? s__('DastProfiles|Validate')
        : s__('DastProfiles|Retry');
    },
    updateSiteProfilesStatuses(normalizedTargetUrl, validationStatus, validationStartedAt) {
      const actualStatus = this.getValidationStatus({ validationStatus, validationStartedAt });

      updateSiteProfilesStatuses({
        fullPath: this.projectPath,
        normalizedTargetUrl,
        status: actualStatus,
        store: this.$apollo.getClient(),
      });
    },
    getValidationStatus({ validationStatus, validationStartedAt }) {
      if (this.isPendingValidation(validationStatus)) {
        const timeDiff = getTimeDifferenceMinutes(validationStartedAt);

        if (timeDiff > DAST_SITE_VALIDATION_ALLOWED_TIMELINE_IN_MINUTES) {
          return FAILED;
        }
      }

      return validationStatus;
    },
    isPendingValidation(status) {
      return [PENDING, INPROGRESS].includes(status);
    },
  },
  EXCLUDED_URLS_SEPARATOR,
  DAST_SITE_VALIDATION_STATUS,
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
          data-testid="validation-button"
          @click="validateUrl(profile.targetUrl)"
          >{{ validateButtonLabel(profile.validationStatus) }}</gl-button
        >
        <dast-site-validation-modal
          v-if="validateTargetUrl"
          :ref="$options.dastSiteValidationModalId"
          :full-path="projectPath"
          :target-url="validateTargetUrl"
          @hidden="validateTargetUrl = null"
          @primary="
            updateSiteProfilesStatuses(
              profile.normalizedTargetUrl,
              $options.DAST_SITE_VALIDATION_STATUS.PENDING,
              profile.validationStartedAt,
            )
          "
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
