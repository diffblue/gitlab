<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlLink,
  GlSkeletonLoader,
  GlSprintf,
  GlSafeHtmlDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { SCAN_TYPE } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import { DAST_SITE_VALIDATION_STATUS } from 'ee/security_configuration/dast_site_validation/constants';
import { initFormField } from 'ee/security_configuration/utils';
import { TYPE_SCANNER_PROFILE, TYPE_SITE_PROFILE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { serializeFormObject } from '~/lib/utils/forms';
import { redirectTo, queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES } from '~/ref/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import validation from '~/vue_shared/directives/validation';
import dastProfileCreateMutation from '../graphql/dast_profile_create.mutation.graphql';
import dastProfileUpdateMutation from '../graphql/dast_profile_update.mutation.graphql';
import {
  ERROR_RUN_SCAN,
  ERROR_FETCH_SCANNER_PROFILES,
  ERROR_FETCH_SITE_PROFILES,
  ERROR_MESSAGES,
  SCANNER_PROFILES_QUERY,
  SITE_PROFILES_QUERY,
} from '../settings';
import { HELP_PAGE_PATH } from '../../on_demand_scans/constants';
import ProfileConflictAlert from './profile_selector/profile_conflict_alert.vue';
import ScannerProfileSelector from './profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from './profile_selector/site_profile_selector.vue';
import ScanSchedule from './scan_schedule.vue';

export const ON_DEMAND_SCANS_STORAGE_KEY = 'on-demand-scans-new-form';

const createProfilesApolloOptions = (name, field, { fetchQuery, fetchError }) => ({
  query: fetchQuery,
  variables() {
    return {
      fullPath: this.projectPath,
    };
  },
  update(data) {
    const nodes = data?.project?.[name]?.nodes ?? [];
    if (nodes.length === 1) {
      this[field] = nodes[0].id;
    }
    return nodes;
  },
  error(e) {
    Sentry.captureException(e);
    this.showErrors(fetchError);
  },
});

export default {
  enabledRefTypes: [REF_TYPE_BRANCHES],
  saveAndRunScanBtnId: 'scan-submit-button',
  saveScanBtnId: 'scan-save-button',
  helpPagePath: HELP_PAGE_PATH,
  components: {
    RefSelector,
    ProfileConflictAlert,
    ScannerProfileSelector,
    SiteProfileSelector,
    ScanSchedule,
    GlAlert,
    GlButton,
    GlCard,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    LocalStorageSync,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
    GlTooltip: GlTooltipDirective,
    validation: validation(),
  },
  apollo: {
    scannerProfiles: createProfilesApolloOptions(
      'scannerProfiles',
      'selectedScannerProfileId',
      SCANNER_PROFILES_QUERY,
    ),
    siteProfiles: createProfilesApolloOptions(
      'siteProfiles',
      'selectedSiteProfileId',
      SITE_PROFILES_QUERY,
    ),
  },
  inject: ['projectPath', 'onDemandScansPath'],
  props: {
    defaultBranch: {
      type: String,
      required: false,
      default: '',
    },
    dastScan: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      form: {
        showValidation: false,
        state: false,
        fields: {
          name: initFormField({ value: this.dastScan?.name ?? '' }),
          description: initFormField({
            value: this.dastScan?.description ?? '',
            required: false,
            skipValidation: true,
          }),
        },
      },
      scannerProfiles: [],
      siteProfiles: [],
      selectedBranch: this.dastScan?.branch?.name ?? this.defaultBranch,
      selectedScannerProfileId: this.dastScan?.dastScannerProfile.id || null,
      selectedSiteProfileId: this.dastScan?.dastSiteProfile.id || null,
      profileSchedule: this.dastScan?.dastProfileSchedule,
      loading: false,
      errorType: null,
      errors: [],
      showAlert: false,
      clearStorage: false,
    };
  },
  computed: {
    dastScanId() {
      return this.dastScan?.id ?? null;
    },
    isEdit() {
      return Boolean(this.dastScanId);
    },
    title() {
      return this.isEdit
        ? s__('OnDemandScans|Edit on-demand DAST scan')
        : s__('OnDemandScans|New on-demand DAST scan');
    },
    selectedScannerProfile() {
      return this.selectedScannerProfileId
        ? this.scannerProfiles.find(({ id }) => id === this.selectedScannerProfileId)
        : null;
    },
    selectedSiteProfile() {
      return this.selectedSiteProfileId
        ? this.siteProfiles.find(({ id }) => id === this.selectedSiteProfileId)
        : null;
    },
    errorMessage() {
      return ERROR_MESSAGES[this.errorType] || null;
    },
    isLoadingProfiles() {
      return ['scannerProfiles', 'siteProfiles'].some((name) => this.$apollo.queries[name].loading);
    },
    failedToLoadProfiles() {
      return [ERROR_FETCH_SCANNER_PROFILES, ERROR_FETCH_SITE_PROFILES].includes(this.errorType);
    },
    someFieldEmpty() {
      const { selectedScannerProfile, selectedSiteProfile } = this;
      return !selectedScannerProfile || !selectedSiteProfile;
    },
    isActiveScannerProfile() {
      return this.selectedScannerProfile?.scanType === SCAN_TYPE.ACTIVE;
    },
    isValidatedSiteProfile() {
      return this.selectedSiteProfile?.validationStatus === DAST_SITE_VALIDATION_STATUS.PASSED;
    },
    hasProfilesConflict() {
      return !this.someFieldEmpty && this.isActiveScannerProfile && !this.isValidatedSiteProfile;
    },
    isFormInvalid() {
      return this.someFieldEmpty || this.hasProfilesConflict;
    },
    isSubmitButtonDisabled() {
      const {
        isFormInvalid,
        loading,
        $options: { saveAndRunScanBtnId },
      } = this;
      return isFormInvalid || (loading && loading !== saveAndRunScanBtnId);
    },
    isSaveButtonDisabled() {
      const {
        isFormInvalid,
        loading,
        $options: { saveScanBtnId },
      } = this;
      return isFormInvalid || (loading && loading !== saveScanBtnId);
    },
    formFieldValues() {
      const {
        selectedScannerProfileId,
        selectedSiteProfileId,
        selectedBranch,
        profileSchedule,
      } = this;
      return {
        ...serializeFormObject(this.form.fields),
        selectedScannerProfileId,
        selectedSiteProfileId,
        selectedBranch,
        profileSchedule,
      };
    },
    storageKey() {
      return `${this.projectPath}/${ON_DEMAND_SCANS_STORAGE_KEY}`;
    },
  },
  created() {
    const params = queryToObject(window.location.search, { legacySpacesDecode: true });

    this.selectedSiteProfileId = params.site_profile_id
      ? convertToGraphQLId(TYPE_SITE_PROFILE, params.site_profile_id)
      : this.selectedSiteProfileId;
    this.selectedScannerProfileId = params.scanner_profile_id
      ? convertToGraphQLId(TYPE_SCANNER_PROFILE, params.scanner_profile_id)
      : this.selectedScannerProfileId;
  },
  methods: {
    onSubmit({ runAfter = true, button = this.$options.saveAndRunScanBtnId } = {}) {
      this.form.showValidation = true;
      if (!this.form.state) {
        return;
      }

      this.loading = button;
      this.hideErrors();
      const mutation = this.isEdit ? dastProfileUpdateMutation : dastProfileCreateMutation;
      const responseType = this.isEdit ? 'dastProfileUpdate' : 'dastProfileCreate';
      const input = {
        dastScannerProfileId: this.selectedScannerProfile.id,
        dastSiteProfileId: this.selectedSiteProfile.id,
        branchName: this.selectedBranch,
        dastProfileSchedule: this.profileSchedule,
        ...(this.isEdit ? { id: this.dastScan.id } : { fullPath: this.projectPath }),
        ...serializeFormObject(this.form.fields),
        [this.isEdit ? 'runAfterUpdate' : 'runAfterCreate']: runAfter,
      };

      this.$apollo
        .mutate({
          mutation,
          variables: {
            input,
          },
        })
        .then(({ data }) => {
          const response = data[responseType];
          const { errors } = response;
          if (errors?.length) {
            this.showErrors(ERROR_RUN_SCAN, errors);
            this.loading = false;
          } else if (!runAfter) {
            redirectTo(this.onDemandScansPath);
            this.clearStorage = true;
          } else {
            this.clearStorage = true;
            redirectTo(response.pipelineUrl);
          }
        })
        .catch((e) => {
          Sentry.captureException(e);
          this.showErrors(ERROR_RUN_SCAN);
          this.loading = false;
        });
    },
    onCancelClicked() {
      this.clearStorage = true;
      redirectTo(this.onDemandScansPath);
    },
    showErrors(errorType, errors = []) {
      this.errorType = errorType;
      this.errors = errors;
      this.showAlert = true;
    },
    hideErrors() {
      this.errorType = null;
      this.errors = [];
      this.showAlert = false;
    },
    updateFromStorage(val) {
      const {
        selectedSiteProfileId,
        selectedScannerProfileId,
        profileSchedule,
        name,
        description,
        selectedBranch,
      } = val;

      this.form.fields.name.value = name ?? this.form.fields.name.value;
      this.form.fields.description.value = description ?? this.form.fields.description.value;
      this.selectedBranch = selectedBranch;
      this.profileSchedule = profileSchedule ?? this.profileSchedule;
      // precedence is given to profile IDs passed from the query params
      this.selectedSiteProfileId = this.selectedSiteProfileId ?? selectedSiteProfileId;
      this.selectedScannerProfileId = this.selectedScannerProfileId ?? selectedScannerProfileId;
    },
  },
};
</script>

<template>
  <gl-form novalidate @submit.prevent="onSubmit()">
    <local-storage-sync
      v-if="!isEdit"
      as-json
      :storage-key="storageKey"
      :clear="clearStorage"
      :value="formFieldValues"
      @input="updateFromStorage"
    />
    <header class="gl-mb-6">
      <div class="gl-mt-6 gl-display-flex">
        <h2 class="gl-flex-grow-1 gl-my-0">{{ title }}</h2>
        <gl-button :href="onDemandScansPath" data-testid="manage-profiles-link">
          {{ s__('OnDemandScans|Manage DAST scans') }}
        </gl-button>
      </div>
      <p>
        <gl-sprintf
          :message="
            s__(
              'OnDemandScans|On-demand scans run outside the DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Learn more%{learnMoreLinkEnd}',
            )
          "
        >
          <template #learnMoreLink="{ content }">
            <gl-link :href="$options.helpPagePath" data-testid="help-page-link">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </header>

    <gl-alert
      v-if="showAlert"
      variant="danger"
      class="gl-mb-5"
      data-testid="on-demand-scan-error"
      :dismissible="!failedToLoadProfiles"
      @dismiss="hideErrors"
    >
      {{ errorMessage }}
      <ul v-if="errors.length" class="gl-mt-3 gl-mb-0">
        <li v-for="error in errors" :key="error" v-safe-html="error"></li>
      </ul>
    </gl-alert>

    <template v-if="isLoadingProfiles">
      <gl-skeleton-loader :width="1248" :height="180">
        <rect x="0" y="0" width="100" height="15" rx="4" />
        <rect x="0" y="24" width="460" height="32" rx="4" />
        <rect x="0" y="71" width="100" height="15" rx="4" />
        <rect x="0" y="95" width="460" height="72" rx="4" />
      </gl-skeleton-loader>
      <gl-card v-for="i in 2" :key="i" class="gl-mb-5">
        <template #header>
          <gl-skeleton-loader :width="1248" :height="15">
            <rect x="0" y="0" width="300" height="15" rx="4" />
          </gl-skeleton-loader>
        </template>
        <gl-skeleton-loader :width="1248" :height="15">
          <rect x="0" y="0" width="600" height="15" rx="4" />
        </gl-skeleton-loader>
        <gl-skeleton-loader :width="1248" :height="15">
          <rect x="0" y="0" width="300" height="15" rx="4" />
        </gl-skeleton-loader>
      </gl-card>
    </template>
    <template v-else-if="!failedToLoadProfiles">
      <gl-form-group
        :label="s__('OnDemandScans|Scan name')"
        :invalid-feedback="form.fields.name.feedback"
      >
        <gl-form-input
          v-model="form.fields.name.value"
          v-validation:[form.showValidation]
          class="mw-460"
          data-testid="dast-scan-name-input"
          type="text"
          :placeholder="s__('OnDemandScans|My daily scan')"
          :state="form.fields.name.state"
          name="name"
          required
        />
      </gl-form-group>
      <gl-form-group :label="s__('OnDemandScans|Description (optional)')">
        <gl-form-textarea
          v-model="form.fields.description.value"
          class="mw-460"
          data-testid="dast-scan-description-input"
          :placeholder="s__(`OnDemandScans|For example: Tests the login page for SQL injections`)"
          name="description"
          :state="form.fields.description.state"
        />
      </gl-form-group>

      <gl-form-group :label="__('Branch')">
        <ref-selector
          v-model="selectedBranch"
          data-testid="dast-scan-branch-input"
          no-flip
          :enabled-ref-types="$options.enabledRefTypes"
          :project-id="projectPath"
          :translations="{
            dropdownHeader: __('Select a branch'),
            searchPlaceholder: __('Search'),
            noRefSelected: __('No available branches'),
            noResults: __('No available branches'),
          }"
        />
        <div v-if="!defaultBranch" class="gl-text-red-500 gl-mt-3">
          {{
            s__(
              'OnDemandScans|You must create a repository within your project to run an on-demand scan.',
            )
          }}
        </div>
      </gl-form-group>

      <scanner-profile-selector
        v-model="selectedScannerProfileId"
        class="gl-mb-5"
        :profiles="scannerProfiles"
        :selected-profile="selectedScannerProfile"
        :has-conflict="hasProfilesConflict"
        :dast-scan-id="dastScanId"
      />
      <site-profile-selector
        v-model="selectedSiteProfileId"
        class="gl-mb-5"
        :profiles="siteProfiles"
        :selected-profile="selectedSiteProfile"
        :has-conflict="hasProfilesConflict"
        :dast-scan-id="dastScanId"
      />

      <scan-schedule v-model="profileSchedule" class="gl-mb-5" />

      <profile-conflict-alert
        v-if="hasProfilesConflict"
        data-testid="on-demand-scans-profiles-conflict-alert"
      />

      <div class="gl-mt-6 gl-pt-6">
        <gl-button
          type="submit"
          variant="confirm"
          class="js-no-auto-disable"
          data-testid="on-demand-scan-submit-button"
          :disabled="isSubmitButtonDisabled"
          :loading="loading === $options.saveAndRunScanBtnId"
        >
          {{ s__('OnDemandScans|Save and run scan') }}
        </gl-button>
        <gl-button
          variant="confirm"
          category="secondary"
          data-testid="on-demand-scan-save-button"
          :disabled="isSaveButtonDisabled"
          :loading="loading === $options.saveScanBtnId"
          @click="onSubmit({ runAfter: false, button: $options.saveScanBtnId })"
        >
          {{ s__('OnDemandScans|Save scan') }}
        </gl-button>
        <gl-button
          data-testid="on-demand-scan-cancel-button"
          :disabled="Boolean(loading)"
          @click="onCancelClicked"
        >
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </template>
  </gl-form>
</template>
