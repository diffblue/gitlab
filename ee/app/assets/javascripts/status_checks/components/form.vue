<script>
import { GlAlert, GlFormGroup, GlFormInput } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { isEqual, isNumber } from 'lodash';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import { isSafeURL } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { ALL_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';
import { EMPTY_STATUS_CHECK, NAME_TAKEN_SERVER_ERROR, URL_TAKEN_SERVER_ERROR } from '../constants';

export default {
  components: {
    ProtectedBranchesSelector,
    GlAlert,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    serverValidationErrors: {
      type: Array,
      required: false,
      default: () => [],
    },
    statusCheck: {
      type: Object,
      required: false,
      default: () => EMPTY_STATUS_CHECK,
    },
  },
  data() {
    const { protectedBranches: branches, name, externalUrl: url } = this.statusCheck;

    return {
      branches,
      branchesToAdd: [],
      branchesApiFailed: false,
      name,
      showValidation: false,
      url,
    };
  },
  computed: {
    isValid() {
      return this.isValidName && this.isValidUrl && this.isValidBranches;
    },
    isValidBranches() {
      return this.branches.every((branch) => isEqual(branch, ALL_BRANCHES) || isNumber(branch?.id));
    },
    isValidName() {
      return Boolean(this.name);
    },
    isValidUrl() {
      return Boolean(this.url) && isSafeURL(this.url);
    },
    branchesState() {
      return !this.showValidation || this.isValidBranches;
    },
    nameState() {
      return (
        !this.showValidation ||
        (this.isValidName && !this.serverValidationErrors.includes(NAME_TAKEN_SERVER_ERROR))
      );
    },
    urlState() {
      return (
        !this.showValidation ||
        (this.isValidUrl && !this.serverValidationErrors.includes(URL_TAKEN_SERVER_ERROR))
      );
    },
    invalidNameMessage() {
      if (this.serverValidationErrors.includes(NAME_TAKEN_SERVER_ERROR)) {
        return this.$options.i18n.validations.nameTaken;
      }

      return this.$options.i18n.validations.nameMissing;
    },
    invalidUrlMessage() {
      if (this.serverValidationErrors.includes(URL_TAKEN_SERVER_ERROR)) {
        return this.$options.i18n.validations.urlTaken;
      }

      return this.$options.i18n.validations.invalidUrl;
    },
  },
  watch: {
    branchesToAdd(value) {
      this.branches = value ? [value] : [];
    },
  },
  methods: {
    submit() {
      this.showValidation = true;

      if (this.isValid) {
        const { branches, name, url } = this;

        this.$emit('submit', { branches, name, url });
      }
    },
    setBranchApiError({ hasErrored, error }) {
      if (!this.branchesApiFailed && error) {
        Sentry.captureException(error);
      }

      this.branchesApiFailed = hasErrored;
    },
  },
  i18n: {
    form: {
      addStatusChecks: s__('StatusCheck|API to check'),
      statusChecks: s__('StatusCheck|Status to check'),
      statusChecksDescription: s__(
        'StatusCheck|Invoke an external API as part of the pipeline process.',
      ),
      nameLabel: s__('StatusCheck|Service name'),
      nameDescription: s__('StatusCheck|Examples: QA, Security.'),
      protectedBranchLabel: s__('StatusCheck|Target branch'),
      protectedBranchDescription: s__(
        'StatusCheck|Apply this status check to all branches or a specific protected branch.',
      ),
    },
    validations: {
      branchesRequired: __('Please select a valid target branch.'),
      branchesApiFailure: __('Unable to fetch branches list, please close the form and try again'),
      nameTaken: __('Name is already taken.'),
      nameMissing: __('Please provide a name.'),
      urlTaken: s__('StatusCheck|External API is already in use by another status check.'),
      invalidUrl: __('Please provide a valid URL.'),
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="branchesApiFailed" class="gl-mb-5" :dismissible="false" variant="danger">
      {{ $options.i18n.validations.branchesApiFailure }}
    </gl-alert>
    <form novalidate @submit.prevent.stop="submit">
      <gl-form-group
        :label="$options.i18n.form.nameLabel"
        :description="$options.i18n.form.nameDescription"
        :state="nameState"
        :invalid-feedback="invalidNameMessage"
        data-testid="name-group"
      >
        <gl-form-input v-model="name" :state="nameState" data-testid="name" />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.form.addStatusChecks"
        :description="$options.i18n.form.statusChecksDescription"
        :state="urlState"
        :invalid-feedback="invalidUrlMessage"
        data-testid="url-group"
      >
        <gl-form-input
          v-model="url"
          :state="urlState"
          type="url"
          :placeholder="`https://api.gitlab.com/`"
          data-testid="url"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.form.protectedBranchLabel"
        :description="$options.i18n.form.protectedBranchDescription"
        :state="branchesState"
        :invalid-feedback="$options.i18n.validations.branchesRequired"
        data-testid="branches-group"
      >
        <protected-branches-selector
          v-model="branchesToAdd"
          :project-id="projectId"
          :is-invalid="!branchesState"
          :selected-branches="branches"
          @apiError="setBranchApiError"
        />
      </gl-form-group>
    </form>
  </div>
</template>
