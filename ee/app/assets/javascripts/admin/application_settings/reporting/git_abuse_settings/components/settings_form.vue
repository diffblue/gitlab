<script>
import { GlForm, GlFormGroup, GlFormInput, GlButton, GlToggle } from '@gitlab/ui';
import { sprintf } from '~/locale';

import {
  validateNumberOfRepos,
  validateReportingTimePeriod,
  validateAllowedUsers,
  validateAlertedUsers,
} from '../validations';

import {
  NUM_REPO_LABEL,
  NUM_REPO_DESCRIPTION,
  REPORTING_TIME_PERIOD_LABEL,
  ALLOWED_USERS_LABEL,
  ALLOWED_USERS_DESCRIPTION,
  ALERTED_USERS_LABEL,
  ALERTED_USERS_DESCRIPTION,
  AUTO_BAN_TOGGLE_LABEL,
  SAVE_CHANGES,
} from '../constants';

import UsersSelect from './users_select.vue';

export default {
  name: 'GitAbuseRateLimitSettingsForm',
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlButton,
    GlToggle,
    UsersSelect,
  },
  i18n: {
    NUM_REPO_LABEL,
    NUM_REPO_DESCRIPTION,
    REPORTING_TIME_PERIOD_LABEL,
    ALLOWED_USERS_LABEL,
    ALLOWED_USERS_DESCRIPTION,
    ALERTED_USERS_LABEL,
    ALERTED_USERS_DESCRIPTION,
    AUTO_BAN_TOGGLE_LABEL,
    SAVE_CHANGES,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
      default: false,
    },
    maxDownloads: {
      type: Number,
      required: false,
      default: 0,
    },
    timePeriod: {
      type: Number,
      required: false,
      default: 0,
    },
    allowlist: {
      type: Array,
      required: false,
      default: () => [],
    },
    alertlist: {
      type: Array,
      required: false,
      default: () => [],
    },
    autoBanUsers: {
      type: Boolean,
      required: false,
      default: false,
    },
    scope: {
      type: String,
      required: false,
      default: 'application',
    },
  },
  data() {
    return {
      allowedUserNames: this.allowlist,
      alertedUserIds: this.alertlist,
      numberOfRepos: this.maxDownloads,
      reportingTimePeriod: this.timePeriod,
      autoBanningEnabled: this.autoBanUsers,
      formErrors: {
        numberOfRepos: '',
        reportingTimePeriod: '',
        allowedUserNames: '',
        alertedUserIds: '',
      },
    };
  },
  computed: {
    formHasError() {
      return Object.values(this.formErrors).some(Boolean);
    },
    autoBanToggleLabel() {
      return sprintf(this.$options.i18n.AUTO_BAN_TOGGLE_LABEL, { scope: this.scope });
    },
  },
  methods: {
    updateGitAbuseRateLimitSettings() {
      this.$emit('submit', {
        maxDownloads: this.numberOfRepos,
        timePeriod: this.reportingTimePeriod,
        allowlist: this.allowedUserNames,
        alertlist: this.alertedUserIds,
        autoBanUsers: this.autoBanningEnabled,
      });
    },
    changedAllowedUsers(userNames) {
      this.allowedUserNames = userNames;
      this.formErrors.allowedUserNames = validateAllowedUsers(this.allowedUserNames);
    },
    changedAlertedUsers(userIds) {
      this.alertedUserIds = userIds;
      this.formErrors.alertedUserIds = validateAlertedUsers(this.alertedUserIds);
    },
    checkNumberOfRepos() {
      this.formErrors.numberOfRepos = validateNumberOfRepos(this.numberOfRepos);
    },
    checkReportingTimePeriod() {
      this.formErrors.reportingTimePeriod = validateReportingTimePeriod(this.reportingTimePeriod);
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="updateGitAbuseRateLimitSettings">
    <gl-form-group
      :label="$options.i18n.NUM_REPO_LABEL"
      :description="$options.i18n.NUM_REPO_DESCRIPTION"
      label-for="number-of-repos"
      :state="!formErrors.numberOfRepos"
      :invalid-feedback="formErrors.numberOfRepos"
      data-testid="number-of-repos-group"
    >
      <gl-form-input
        id="number-of-repos"
        v-model="numberOfRepos"
        type="number"
        :class="{ 'is-invalid': Boolean(formErrors.numberOfRepos) }"
        data-testid="number-of-repos-input"
        @blur="checkNumberOfRepos"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.REPORTING_TIME_PERIOD_LABEL"
      label-for="reporting-time-period"
      :state="!formErrors.reportingTimePeriod"
      :invalid-feedback="formErrors.reportingTimePeriod"
      data-testid="reporting-time-period-group"
    >
      <gl-form-input
        id="reporting-time-period"
        v-model="reportingTimePeriod"
        type="number"
        :class="{ 'is-invalid': Boolean(formErrors.reportingTimePeriod) }"
        data-testid="reporting-time-period-input"
        @blur="checkReportingTimePeriod"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.ALLOWED_USERS_LABEL"
      label-for="allowed-users"
      :state="!formErrors.allowedUserNames"
      :invalid-feedback="formErrors.allowedUserNames"
      data-testid="allowed-users-group"
    >
      <template #description>
        <div class="gl-mt-3">
          {{ $options.i18n.ALLOWED_USERS_DESCRIPTION }}
        </div>
      </template>
      <users-select
        input-id="allowed-users"
        :selected="allowedUserNames"
        data-testid="allowed-users"
        @selection-changed="changedAllowedUsers"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.ALERTED_USERS_LABEL"
      label-for="alerted-users"
      :state="!formErrors.alertedUserIds"
      :invalid-feedback="formErrors.alertedUserIds"
      data-testid="alerted-users-group"
    >
      <template #description>
        <div class="gl-mt-3">
          {{ $options.i18n.ALERTED_USERS_DESCRIPTION }}
        </div>
      </template>
      <users-select
        input-id="alerted-users"
        :select-by-username="false"
        :selected="alertedUserIds"
        data-testid="alerted-users"
        @selection-changed="changedAlertedUsers"
      />
    </gl-form-group>
    <gl-form-group>
      <gl-toggle
        v-model="autoBanningEnabled"
        :label="autoBanToggleLabel"
        class="gl-mb-4"
        data-testid="auto-ban-users-toggle"
      />
    </gl-form-group>
    <gl-button
      :loading="isLoading"
      type="submit"
      variant="confirm"
      category="primary"
      :disabled="formHasError"
    >
      {{ $options.i18n.SAVE_CHANGES }}
    </gl-button>
  </gl-form>
</template>
