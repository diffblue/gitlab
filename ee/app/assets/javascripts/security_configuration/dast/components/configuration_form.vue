<script>
import { GlLink, GlSprintf, GlButton, GlForm, GlAlert } from '@gitlab/ui';
import DastProfilesSelector from 'ee/on_demand_scans_form/components/profile_selector/dast_profiles_selector.vue';
import ConfigurationSnippetModal from 'ee/security_configuration/components/configuration_snippet_modal.vue';
import { CONFIGURATION_SNIPPET_MODAL_ID } from 'ee/security_configuration/components/constants';
import { s__, __ } from '~/locale';
import { CODE_SNIPPET_SOURCE_DAST } from '~/pipeline_editor/components/code_snippet_alert/constants';
import { DAST_HELP_PATH } from '~/security_configuration/components/constants';
import {
  DAST_YAML_CONFIGURATION_TEMPLATE as template,
  DAST_SCANNER_PROFILE_PLACEHOLDER,
  DAST_SITE_PROFILE_PLACEHOLDER,
} from '../constants';

export default {
  DAST_HELP_PATH,
  CONFIGURATION_SNIPPET_MODAL_ID,
  CODE_SNIPPET_SOURCE_DAST,
  components: {
    GlLink,
    GlSprintf,
    GlButton,
    GlForm,
    GlAlert,
    ConfigurationSnippetModal,
    DastProfilesSelector,
  },
  inject: ['gitlabCiYamlEditPath', 'securityConfigurationPath'],
  i18n: {
    helpText: s__(`
      DastConfig|Customize DAST settings to suit your requirements. Configuration changes made here override those provided by GitLab and are excluded from updates. For details of more advanced configuration options, see the %{docsLinkStart}GitLab DAST documentation%{docsLinkEnd}.`),
    submitButtonText: s__('DastConfig|Generate code snippet'),
    cancelText: __('Cancel'),
  },
  data() {
    return {
      selectedScannerProfileName: '',
      selectedSiteProfileName: '',
      isLoading: false,
      hasProfilesConflict: false,
      errorMessage: '',
      showAlert: false,
    };
  },
  computed: {
    configurationYaml() {
      return template
        .replace(DAST_SITE_PROFILE_PLACEHOLDER, this.selectedSiteProfileName)
        .replace(DAST_SCANNER_PROFILE_PLACEHOLDER, this.selectedScannerProfileName);
    },
    isSubmitDisabled() {
      return (
        !this.selectedScannerProfileName ||
        !this.selectedSiteProfileName ||
        this.hasProfilesConflict
      );
    },
  },
  methods: {
    onSubmit() {
      this.$refs[CONFIGURATION_SNIPPET_MODAL_ID].show();
    },
    updateProfiles(profiles) {
      this.selectedScannerProfileName = profiles.scannerProfile?.profileName;
      this.selectedSiteProfileName = profiles.siteProfile?.profileName;
    },
    showErrors(error) {
      this.errorMessage = error;
      this.showAlert = true;
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="onSubmit">
    <section class="gl-mt-5">
      <p>
        <gl-sprintf :message="$options.i18n.helpText">
          <template #docsLink="{ content }">
            <gl-link :href="$options.DAST_HELP_PATH" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </section>

    <gl-alert
      v-if="showAlert"
      variant="danger"
      class="gl-mb-5"
      data-testid="dast-configuration-error"
      :dismissible="false"
    >
      {{ errorMessage }}
    </gl-alert>

    <dast-profiles-selector
      @profiles-selected="updateProfiles"
      @error="showErrors"
      @profiles-has-conflict="hasProfilesConflict = $event"
    />

    <gl-button
      :disabled="isSubmitDisabled"
      :loading="isLoading"
      type="submit"
      variant="confirm"
      class="js-no-auto-disable"
      data-testid="dast-configuration-submit-button"
      >{{ $options.i18n.submitButtonText }}</gl-button
    >
    <gl-button
      :disabled="isLoading"
      :href="securityConfigurationPath"
      data-testid="dast-configuration-cancel-button"
      >{{ $options.i18n.cancelText }}</gl-button
    >

    <configuration-snippet-modal
      :ref="$options.CONFIGURATION_SNIPPET_MODAL_ID"
      :ci-yaml-edit-url="gitlabCiYamlEditPath"
      :yaml="configurationYaml"
      :redirect-param="$options.CODE_SNIPPET_SOURCE_DAST"
      scan-type="DAST"
    />
  </gl-form>
</template>
