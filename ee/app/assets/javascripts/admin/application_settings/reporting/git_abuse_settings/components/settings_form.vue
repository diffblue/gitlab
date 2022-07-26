<script>
import { GlForm, GlFormGroup, GlFormInput, GlButton } from '@gitlab/ui';

import {
  validateNumberOfRepos,
  validateReportingTimePeriod,
  validateExcludedUsers,
} from '../validations';

import {
  NUM_REPO_LABEL,
  NUM_REPO_DESCRIPTION,
  REPORTING_TIME_PERIOD_LABEL,
  EXCLUDED_USERS_LABEL,
  EXCLUDED_USERS_DESCRIPTION,
  SAVE_CHANGES,
} from '../constants';

import UsersAllowlist from './users_allowlist.vue';

export default {
  name: 'GitAbuseRateLimitSettingsForm',
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlButton,
    UsersAllowlist,
  },
  i18n: {
    NUM_REPO_LABEL,
    NUM_REPO_DESCRIPTION,
    REPORTING_TIME_PERIOD_LABEL,
    EXCLUDED_USERS_LABEL,
    EXCLUDED_USERS_DESCRIPTION,
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
  },
  data() {
    return {
      excludedUsers: this.allowlist,
      numberOfRepos: this.maxDownloads,
      reportingTimePeriod: this.timePeriod,
      formErrors: {
        numberOfRepos: '',
        reportingTimePeriod: '',
        excludedUsers: '',
      },
    };
  },
  computed: {
    formHasError() {
      return Object.values(this.formErrors).some(Boolean);
    },
  },
  methods: {
    updateGitAbuseRateLimitSettings() {
      this.$emit('submit', {
        maxDownloads: this.numberOfRepos,
        timePeriod: this.reportingTimePeriod,
        allowlist: this.excludedUsers,
      });
    },
    addToExcludedUsers(username) {
      this.excludedUsers.push(username);
      this.formErrors.excludedUsers = validateExcludedUsers(this.excludedUsers);
    },
    removeFromExcludedUsers(username) {
      this.excludedUsers = this.excludedUsers.filter((x) => x !== username);
      this.formErrors.excludedUsers = validateExcludedUsers(this.excludedUsers);
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
      :state="!Boolean(formErrors.numberOfRepos)"
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
      :state="!Boolean(formErrors.reportingTimePeriod)"
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
      :label="$options.i18n.EXCLUDED_USERS_LABEL"
      label-for="excluded-users"
      :state="!Boolean(formErrors.excludedUsers)"
      :invalid-feedback="formErrors.excludedUsers"
      data-testid="excluded-users-group"
    >
      <template #description>
        <div class="gl-mt-3">
          {{ $options.i18n.EXCLUDED_USERS_DESCRIPTION }}
        </div>
      </template>
      <users-allowlist
        :excluded-usernames="excludedUsers"
        @user-added="addToExcludedUsers"
        @user-removed="removeFromExcludedUsers"
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
