<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlIcon,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlLink,
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
import { s__, __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES } from '~/ref/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import validation from '~/vue_shared/directives/validation';
import {
  HELP_PAGE_PATH,
  DAST_CONFIGURATION_HELP_PATH,
  SCANNER_TYPE,
  SITE_TYPE,
} from 'ee/on_demand_scans/constants';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import DastProfilesConfigurator from 'ee/security_configuration/dast_profiles/dast_profiles_configurator/dast_profiles_configurator.vue';
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
import ProfileConflictAlert from './profile_selector/profile_conflict_alert.vue';
import ScannerProfileSelector from './profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from './profile_selector/site_profile_selector.vue';
import ScanSchedule from './scan_schedule.vue';

export const ON_DEMAND_SCANS_STORAGE_KEY = 'on-demand-scans-new-form';

/**
 * TODO Can be removed after rolling out
 * dastUiRedesign feature flag
 * Content was transferred to DastProfilesConfigurator
 */
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
  dastConfigurationHelpPath: DAST_CONFIGURATION_HELP_PATH,
  SCANNER_TYPE,
  SITE_TYPE,
  i18n: {
    newOnDemandScanHeader: s__('OnDemandScans|New on-demand scan'),
    newOnDemandScanHeaderDescription: s__(
      'OnDemandScans|On-demand scans run outside the DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Learn more%{learnMoreLinkEnd}',
    ),
    editOnDemandScanHeader: s__('OnDemandScans|Edit on-demand scan'),
    branchSelectorHelpText: s__(
      'OnDemandScans|Scan results will be associated with the selected branch.',
    ),
    dastConfigurationHeader: s__('OnDemandScans|DAST configuration'),
    dastConfigurationDescription: s__(
      "OnDemandScans|DAST scans for vulnerabilities in your project's running application, website, or API.  For details of all configuration options, see the %{linkStart}GitLab DAST documentation%{linkEnd}.",
    ),
    scanConfigurationNameLabel: s__('OnDemandScans|Scan name'),
    scanConfigurationNamePlaceholder: s__('OnDemandScans|My daily scan'),
    scanConfigurationDescriptionLabel: s__('OnDemandScans|Description (optional)'),
    scanConfigurationDescriptionPlaceholder: s__(
      `OnDemandScans|For example: Tests the login page for SQL injections`,
    ),
    scanConfigurationBranchDropDown: {
      dropdownHeader: __('Select a branch'),
      searchPlaceholder: __('Search'),
      noRefSelected: __('No available branches'),
      noResults: __('No available branches'),
    },
    scanConfigurationHeader: s__('OnDemandScans|Scan configuration'),
    scanConfigurationDescription: s__(
      'OnDemandScans|Define the fundamental configuration options for your on-demand scan.',
    ),
    scanConfigurationDefaultBranchLabel: s__(
      'OnDemandScans|You must create a repository within your project to run an on-demand scan.',
    ),
    scanTypeHeader: s__('OnDemandScans|Scan type'),
    scanTypeText: s__('OnDemandScans|Dynamic Application Security Testing (DAST)'),
    scanTypeTooltip: s__(
      'OnDemandScans|Analyze a deployed version of your web application for known vulnerabilities by examining it from the outside in. DAST works by simulating external attacks on your application while it is running.',
    ),
    scanScheduleHeader: s__('OnDemandScans|Scan schedule'),
    scanScheduleDescription: s__(
      'OnDemandScans|Add a schedule to run this scan at a specified date and time or on a recurring basis. Scheduled scans are automatically saved to scan library.',
    ),
    saveAndRunScanButton: s__('OnDemandScans|Save and run scan'),
    saveScanButton: s__('OnDemandScans|Save scan'),
    cancelButton: s__('OnDemandScans|Cancel'),
  },
  components: {
    RefSelector,
    ProfileConflictAlert,
    ScannerProfileSelector,
    SiteProfileSelector,
    ScanSchedule,
    GlAlert,
    GlButton,
    GlForm,
    GlIcon,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlLink,
    GlSprintf,
    LocalStorageSync,
    SectionLayout,
    ConfigurationPageLayout,
    DastProfilesConfigurator,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
    GlTooltip: GlTooltipDirective,
    validation: validation(),
  },
  mixins: [glFeatureFlagMixin()],
  /**
   * TODO Can be removed after rolling out
   * dastUiRedesign feature flag
   * Content was transferred to DastProfilesConfigurator
   */
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
    /**
     *  TODO remove after dastUiRedesign flag roll out
     */
    dastScanId() {
      return this.dastScan?.id ?? null;
    },
    isEdit() {
      return Boolean(this.dastScanId);
    },
    title() {
      return this.isEdit
        ? this.$options.i18n.editOnDemandScanHeader
        : this.$options.i18n.newOnDemandScanHeader;
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
      return this.glFeatures.dastUiRedesign
        ? this.errorType
        : ERROR_MESSAGES[this.errorType] || null;
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
    selectProfiles({ scannerProfile, siteProfile }) {
      this.selectedSiteProfileId = siteProfile?.id;
      this.selectedScannerProfileId = scannerProfile?.id;
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
  <configuration-page-layout>
    <template #heading>
      {{ title }}
    </template>
    <template #description>
      <gl-sprintf :message="$options.i18n.newOnDemandScanHeaderDescription">
        <template #learnMoreLink="{ content }">
          <gl-link :href="$options.helpPagePath" data-testid="help-page-link">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </template>
    <gl-form novalidate @submit.prevent="onSubmit()">
      <local-storage-sync
        v-if="!isEdit"
        :storage-key="storageKey"
        :clear="clearStorage"
        :value="formFieldValues"
        @input="updateFromStorage"
      />

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
      <section-layout
        v-if="!failedToLoadProfiles"
        :heading="$options.i18n.scanConfigurationHeader"
        :is-loading="isLoadingProfiles"
      >
        <template #description>
          <p>{{ $options.i18n.scanConfigurationDescription }}</p>
        </template>
        <template #features>
          <gl-form-group
            class="gl-mb-6"
            :label="$options.i18n.scanConfigurationNameLabel"
            :invalid-feedback="form.fields.name.feedback"
          >
            <gl-form-input
              v-model="form.fields.name.value"
              v-validation:[form.showValidation]
              data-testid="dast-scan-name-input"
              type="text"
              :placeholder="$options.i18n.scanConfigurationNamePlaceholder"
              :state="form.fields.name.state"
              name="name"
              required
            />
          </gl-form-group>

          <gl-form-group class="gl-mb-6" :label="$options.i18n.scanConfigurationDescriptionLabel">
            <gl-form-textarea
              v-model="form.fields.description.value"
              data-testid="dast-scan-description-input"
              :placeholder="$options.i18n.scanConfigurationDescriptionPlaceholder"
              name="description"
              :state="form.fields.description.state"
            />
          </gl-form-group>

          <gl-form-group class="gl-mb-6" :label="$options.i18n.scanTypeHeader">
            <span>{{ $options.i18n.scanTypeText }}</span>
            <gl-icon
              v-gl-tooltip="$options.i18n.scanTypeTooltip"
              name="question-o"
              class="gl-ml-2 gl-link gl-cursor-pointer"
            />
          </gl-form-group>

          <gl-form-group class="gl-mb-3" :label="__('Branch')">
            <small class="form-text text-gl-muted gl-mt-0 gl-mb-5">
              {{ $options.i18n.branchSelectorHelpText }}
            </small>
            <ref-selector
              v-model="selectedBranch"
              data-testid="dast-scan-branch-input"
              no-flip
              :enabled-ref-types="$options.enabledRefTypes"
              :project-id="projectPath"
              :translations="$options.i18n.scanConfigurationBranchDropDown"
            />
            <div v-if="!defaultBranch" class="gl-text-red-500 gl-mt-3">
              {{ $options.i18n.scanConfigurationDefaultBranchLabel }}
            </div>
          </gl-form-group>
        </template>
      </section-layout>

      <dast-profiles-configurator
        v-if="glFeatures.dastUiRedesign"
        :saved-profiles="dastScan"
        :full-path="projectPath"
        @error="showErrors"
        @profiles-selected="selectProfiles"
      />

      <section-layout
        v-if="!failedToLoadProfiles && !glFeatures.dastUiRedesign"
        :heading="$options.i18n.dastConfigurationHeader"
        :is-loading="isLoadingProfiles"
      >
        <template #description>
          <p>
            <gl-sprintf :message="$options.i18n.dastConfigurationDescription">
              <template #link="{ content }">
                <gl-link :href="$options.dastConfigurationHelpPath">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </p>
        </template>
        <template #features>
          <scanner-profile-selector
            v-model="selectedScannerProfileId"
            class="gl-mb-6"
            :profiles="scannerProfiles"
            :selected-profile="selectedScannerProfile"
            :has-conflict="hasProfilesConflict"
            :dast-scan-id="dastScanId"
          />

          <site-profile-selector
            v-model="selectedSiteProfileId"
            class="gl-mb-2"
            :profiles="siteProfiles"
            :selected-profile="selectedSiteProfile"
            :has-conflict="hasProfilesConflict"
            :dast-scan-id="dastScanId"
          />
        </template>
      </section-layout>

      <section-layout
        v-if="!failedToLoadProfiles"
        :heading="$options.i18n.scanScheduleHeader"
        :is-loading="isLoadingProfiles"
      >
        <template #description>
          <p>{{ $options.i18n.scanScheduleDescription }}</p>
        </template>
        <template #features>
          <scan-schedule v-model="profileSchedule" />
        </template>
      </section-layout>

      <div v-if="!failedToLoadProfiles">
        <profile-conflict-alert
          v-if="hasProfilesConflict"
          class="gl-mt-6"
          data-testid="on-demand-scans-profiles-conflict-alert"
        />

        <div class="gl-pt-6">
          <gl-button
            type="submit"
            variant="confirm"
            class="js-no-auto-disable"
            data-testid="on-demand-scan-submit-button"
            :disabled="isSubmitButtonDisabled"
            :loading="loading === $options.saveAndRunScanBtnId"
          >
            {{ $options.i18n.saveAndRunScanButton }}
          </gl-button>
          <gl-button
            variant="confirm"
            category="secondary"
            data-testid="on-demand-scan-save-button"
            :disabled="isSaveButtonDisabled"
            :loading="loading === $options.saveScanBtnId"
            @click="onSubmit({ runAfter: false, button: $options.saveScanBtnId })"
          >
            {{ $options.i18n.saveScanButton }}
          </gl-button>
          <gl-button
            data-testid="on-demand-scan-cancel-button"
            :disabled="Boolean(loading)"
            @click="onCancelClicked"
          >
            {{ $options.i18n.cancelButton }}
          </gl-button>
        </div>
      </div>
    </gl-form>
  </configuration-page-layout>
</template>
