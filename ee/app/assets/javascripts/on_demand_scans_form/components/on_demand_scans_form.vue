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
  GlPopover,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { SCAN_TYPE } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import { DAST_SITE_VALIDATION_STATUS } from 'ee/security_configuration/dast_site_validation/constants';
import { initFormField } from 'ee/security_configuration/utils';
import { serializeFormObject } from '~/lib/utils/forms';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { s__, __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES } from '~/ref/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import validation from '~/vue_shared/directives/validation';
import {
  DAST_PROFILES_DRAWER,
  PRE_SCAN_VERIFICATION_DRAWER,
  HELP_PAGE_PATH,
  DAST_CONFIGURATION_HELP_PATH,
  SCANNER_TYPE,
  SITE_TYPE,
} from 'ee/on_demand_scans/constants';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import PreScanVerificationConfigurator from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_configurator.vue';
import DastProfilesConfigurator from 'ee/security_configuration/dast_profiles/dast_profiles_configurator/dast_profiles_configurator.vue';
import dastProfileCreateMutation from '../graphql/dast_profile_create.mutation.graphql';
import dastProfileUpdateMutation from '../graphql/dast_profile_update.mutation.graphql';
import {
  ERROR_RUN_SCAN,
  ERROR_FETCH_SCANNER_PROFILES,
  ERROR_FETCH_SITE_PROFILES,
  ERROR_MESSAGES,
} from '../settings';
import ProfileConflictAlert from './profile_selector/profile_conflict_alert.vue';
import RunnerTags from './runner_tags.vue';
import ScanSchedule from './scan_schedule.vue';

export default {
  enabledRefTypes: [REF_TYPE_BRANCHES],
  saveAndRunScanBtnId: 'scan-submit-button',
  saveScanBtnId: 'scan-save-button',
  helpPagePath: HELP_PAGE_PATH,
  dastConfigurationHelpPath: DAST_CONFIGURATION_HELP_PATH,
  SCANNER_TYPE,
  SITE_TYPE,
  DAST_PROFILES_DRAWER,
  PRE_SCAN_VERIFICATION_DRAWER,
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
    runnerTagsLabel: s__('OnDemandScans|Runner tags'),
    runnerTagsDescription: s__(
      'OnDemandScans|Only project owners and maintainers can select runner tags.',
    ),
    scanConfigurationNameLabel: s__('OnDemandScans|Scan name'),
    scanConfigurationNamePlaceholder: s__('OnDemandScans|My daily scan'),
    scanConfigurationDescriptionLabel: s__('OnDemandScans|Description'),
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
    defaultErrorMsg: __('Something went wrong. Please try again.'),
  },
  components: {
    RefSelector,
    ProfileConflictAlert,
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
    SectionLayout,
    ConfigurationPageLayout,
    DastProfilesConfigurator,
    PreScanVerificationConfigurator,
    RunnerTags,
    GlPopover,
  },
  directives: {
    SafeHtml,
    validation: validation(),
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'canEditRunnerTags',
    'projectPath',
    'onDemandScansPath',
    'siteProfilesLibraryPath',
    'scannerProfilesLibraryPath',
  ],
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
      selectedTags: this.dastScan?.tagList || [],
      selectedScannerProfileId: this.dastScan?.dastScannerProfile.id || null,
      selectedSiteProfileId: this.dastScan?.dastSiteProfile.id || null,
      profileSchedule: this.dastScan?.dastProfileSchedule,
      loading: false,
      errorType: null,
      errors: [],
      showAlert: false,
      openedDrawer: null,
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
      const { errorType } = this;
      return errorType ? ERROR_MESSAGES[errorType] : this.$options.i18n.defaultErrorMsg;
    },
    failedToLoadProfiles() {
      return [ERROR_FETCH_SCANNER_PROFILES, ERROR_FETCH_SITE_PROFILES].includes(this.errorType);
    },
    someFieldEmpty() {
      const { selectedScannerProfileId, selectedSiteProfileId } = this;
      return !selectedScannerProfileId || !selectedSiteProfileId;
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
    runnerTagsDescription() {
      return this.canEditRunnerTags ? '' : this.$options.i18n.runnerTagsDescription;
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
    isDastDrawerOpen() {
      return this.openedDrawer === DAST_PROFILES_DRAWER;
    },
    isPreScanVerificationOpen() {
      return this.openedDrawer === PRE_SCAN_VERIFICATION_DRAWER;
    },
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
        dastScannerProfileId: this.selectedScannerProfileId,
        dastSiteProfileId: this.selectedSiteProfileId,
        branchName: this.selectedBranch,
        dastProfileSchedule: this.profileSchedule,
        ...(this.isEdit ? { id: this.dastScan.id } : { fullPath: this.projectPath }),
        ...serializeFormObject(this.form.fields),
        tagList: this.selectedTags,
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
            redirectTo(this.onDemandScansPath); // eslint-disable-line import/no-deprecated
          } else {
            redirectTo(response.pipelineUrl); // eslint-disable-line import/no-deprecated
          }
        })
        .catch((e) => {
          Sentry.captureException(e);
          this.showErrors(ERROR_RUN_SCAN);
          this.loading = false;
        });
    },
    onCancelClicked() {
      redirectTo(this.onDemandScansPath); // eslint-disable-line import/no-deprecated
    },
    showGeneralErrors(message) {
      this.showErrors(null, [message]);
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
    openDrawer(drawer) {
      this.openedDrawer = drawer;
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
      <section-layout v-if="!failedToLoadProfiles" :heading="$options.i18n.scanConfigurationHeader">
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

          <gl-form-group
            class="gl-mb-6"
            optional
            :label="$options.i18n.scanConfigurationDescriptionLabel"
          >
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
              id="scan-type-info"
              name="question-o"
              class="gl-ml-2 gl-link gl-cursor-pointer"
            />
            <gl-popover target="scan-type-info" placement="top" triggers="focus hover">
              <span>{{ $options.i18n.scanTypeTooltip }}</span>
            </gl-popover>
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
          <gl-form-group
            v-if="glFeatures.onDemandScansRunnerTags"
            class="gl-mt-6 gl-mb-3"
            data-testid="on-demand-scan-runner-tags"
            optional
            :label="$options.i18n.runnerTagsLabel"
            :description="runnerTagsDescription"
          >
            <runner-tags
              v-model="selectedTags"
              :can-edit-runner-tags="canEditRunnerTags"
              :project-path="projectPath"
              @error="showGeneralErrors"
            />
          </gl-form-group>
        </template>
      </section-layout>

      <dast-profiles-configurator
        :saved-profiles="dastScan"
        :full-path="projectPath"
        :scanner-profiles-library-path="scannerProfilesLibraryPath"
        :site-profiles-library-path="siteProfilesLibraryPath"
        :open="isDastDrawerOpen"
        @error="showGeneralErrors"
        @profiles-selected="selectProfiles"
        @open-drawer="openDrawer($options.DAST_PROFILES_DRAWER)"
      />

      <section-layout v-if="!failedToLoadProfiles" :heading="$options.i18n.scanScheduleHeader">
        <template #description>
          <p>{{ $options.i18n.scanScheduleDescription }}</p>
        </template>
        <template #features>
          <scan-schedule v-model="profileSchedule" />
        </template>
      </section-layout>

      <pre-scan-verification-configurator
        v-if="!failedToLoadProfiles && glFeatures.dastPreScanVerification"
        class="gl-my-6"
        :open="isPreScanVerificationOpen"
        @open-drawer="openDrawer($options.PRE_SCAN_VERIFICATION_DRAWER)"
      />

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
