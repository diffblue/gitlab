<script>
import {
  GlAccordion,
  GlAccordionItem,
  GlAlert,
  GlButton,
  GlFormGroup,
  GlFormText,
  GlFormCheckbox,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import ConfigurationSnippetModal from 'ee/security_configuration/components/configuration_snippet_modal.vue';
import { CONFIGURATION_SNIPPET_MODAL_ID } from 'ee/security_configuration/components/constants';
import { isEmptyValue } from '~/lib/utils/forms';
import { __, s__ } from '~/locale';
import { CODE_SNIPPET_SOURCE_API_FUZZING } from '~/ci/pipeline_editor/components/code_snippet_alert/constants';
import DropdownInput from '../../components/dropdown_input.vue';
import DynamicFields from '../../components/dynamic_fields.vue';
import FormInput from '../../components/form_input.vue';
import { SCAN_MODES } from '../constants';
import { buildConfigurationSnippet } from '../utils';

export default {
  CONFIGURATION_SNIPPET_MODAL_ID,
  CODE_SNIPPET_SOURCE_API_FUZZING,
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormText,
    GlFormCheckbox,
    GlLink,
    GlSprintf,
    ConfigurationSnippetModal,
    DropdownInput,
    DynamicFields,
    FormInput,
  },
  inject: [
    'securityConfigurationPath',
    'fullPath',
    'gitlabCiYamlEditPath',
    'apiFuzzingAuthenticationDocumentationPath',
    'ciVariablesDocumentationPath',
    'projectCiSettingsPath',
    'canSetProjectCiVariables',
  ],
  props: {
    apiFuzzingCiConfiguration: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      targetUrl: {
        field: 'targetUrl',
        label: s__('APIFuzzing|Target URL'),
        description: s__(
          'APIFuzzing|Base URL of API testing target. For example, http://www.example.com.',
        ),
        placeholder: __('http://www.example.com'),
        value: '',
      },
      scanMode: {
        field: 'scanMode',
        label: s__('APIFuzzing|Scan mode'),
        description: s__('APIFuzzing|There are three ways to perform scans.'),
        value: '',
        defaultText: s__('APIFuzzing|Choose a method'),
        options: this.apiFuzzingCiConfiguration.scanModes.map((value) => ({
          value,
          text: SCAN_MODES[value].scanModeLabel,
        })),
      },
      apiSpecificationFile: {
        field: 'apiSpecificationFile',
        value: '',
      },
      authenticationEnabled: false,
      authenticationSettings: [
        {
          type: 'string',
          field: 'username',
          label: s__('APIFuzzing|Username for basic authentication'),
          description: s__(
            'APIFuzzing|Enter the name of the CI variable containing the username. For example, $VARIABLE_WITH_USERNAME.',
          ),
          placeholder: s__('APIFuzzing|$VARIABLE_WITH_USERNAME'),
          value: '',
        },
        {
          type: 'string',
          field: 'password',
          label: s__('APIFuzzing|Password for basic authentication'),
          description: s__(
            'APIFuzzing|Enter the name of the CI variable containing the password. For example, $VARIABLE_WITH_PASSWORD.',
          ),
          placeholder: s__('APIFuzzing|$VARIABLE_WITH_PASSWORD'),
          value: '',
        },
      ],
      scanProfile: {
        field: 'scanProfile',
        label: s__('APIFuzzing|Scan profile'),
        value: '',
        defaultText: s__('APIFuzzing|Choose a profile'),
        sectionHeader: s__('APIFuzzing|Predefined profiles'),
        options: this.apiFuzzingCiConfiguration.scanProfiles.map(
          ({ name: value, description: text }) => ({
            value,
            text,
          }),
        ),
      },
      configurationYaml: '',
    };
  },
  computed: {
    authAlertI18n() {
      return this.canSetProjectCiVariables
        ? {
            title: s__('APIFuzzing|Make sure your credentials are secured'),
            text: s__(
              `APIFuzzing|To prevent a security leak, authentication info must be added as a
              %{ciVariablesLinkStart}CI variable%{ciVariablesLinkEnd}. As a user with maintainer access
              rights, you can manage CI variables in the
              %{ciSettingsLinkStart}Settings%{ciSettingsLinkEnd} area.`,
            ),
          }
        : {
            title: s__("APIFuzzing|You may need a maintainer's help to secure your credentials."),
            text: s__(
              `APIFuzzing|To prevent a security leak, authentication info must be added as a
              %{ciVariablesLinkStart}CI variable%{ciVariablesLinkEnd}. A user with maintainer
              access rights can manage CI variables in the
              %{ciSettingsLinkStart}Settings%{ciSettingsLinkEnd} area. We detected that you are not
              a maintainer. Commit your changes and assign them to a maintainer to update the
              credentials before merging.`,
            ),
          };
    },
    scanProfileYaml() {
      return this.apiFuzzingCiConfiguration.scanProfiles.find(
        ({ name }) => name === this.scanProfile.value,
      )?.yaml;
    },
    someFieldEmpty() {
      const fields = [this.targetUrl, this.scanMode, this.apiSpecificationFile, this.scanProfile];
      if (this.authenticationEnabled) {
        fields.push(...this.authenticationSettings);
      }
      return fields.some(({ value }) => isEmptyValue(value));
    },
  },
  methods: {
    onSubmit() {
      const options = {
        projectPath: this.fullPath,
        target: this.targetUrl.value,
        scanMode: this.scanMode.value,
        apiSpecificationFile: this.apiSpecificationFile.value,
        scanProfile: this.scanProfile.value,
      };
      if (this.authenticationEnabled) {
        const [authUsername, authPassword] = this.authenticationSettings;
        options.authUsername = authUsername.value;
        options.authPassword = authPassword.value;
      }
      this.configurationYaml = buildConfigurationSnippet(options);
      this.$refs[CONFIGURATION_SNIPPET_MODAL_ID].show();
    },
  },
  SCAN_MODES,
};
</script>

<template>
  <form @submit.prevent="onSubmit">
    <form-input v-model="targetUrl.value" v-bind="targetUrl" class="gl-mb-7" />

    <dropdown-input v-model="scanMode.value" v-bind="scanMode" />
    <form-input
      v-if="scanMode.value"
      v-model="apiSpecificationFile.value"
      v-bind="{ ...apiSpecificationFile, ...$options.SCAN_MODES[scanMode.value] }"
    />

    <gl-form-group class="gl-my-7">
      <template #label>
        {{ __('Authentication') }}
        <gl-form-text class="gl-mt-3">
          <gl-sprintf
            :message="
              s__(
                'APIFuzzing|Configure HTTP basic authentication values. Other authentication methods are supported. %{linkStart}Learn more%{linkEnd}.',
              )
            "
          >
            <template #link="{ content }">
              <a :href="apiFuzzingAuthenticationDocumentationPath">{{ content }}</a>
            </template>
          </gl-sprintf>
        </gl-form-text>
      </template>
      <gl-form-checkbox
        v-model="authenticationEnabled"
        data-testid="api-fuzzing-enable-authentication-checkbox"
      >
        {{ s__('APIFuzzing|Enable authentication') }}
      </gl-form-checkbox>
    </gl-form-group>

    <template v-if="authenticationEnabled">
      <gl-alert
        :title="authAlertI18n.title"
        :dismissible="false"
        variant="warning"
        class="gl-mb-5"
        data-testid="api-fuzzing-authentication-notice"
      >
        <gl-sprintf :message="authAlertI18n.text">
          <template #ciVariablesLink="{ content }">
            <gl-link :href="ciVariablesDocumentationPath" target="_blank">{{ content }}</gl-link>
          </template>
          <template #ciSettingsLink="{ content }">
            <gl-link :href="projectCiSettingsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
      <dynamic-fields v-model="authenticationSettings" />
    </template>

    <dropdown-input v-model="scanProfile.value" v-bind="scanProfile" />
    <template v-if="scanProfileYaml">
      <gl-accordion :header-level="3">
        <gl-accordion-item :title="s__('APIFuzzing|Show code snippet for the profile')">
          <pre data-testid="api-fuzzing-scan-profile-yaml-viewer">{{ scanProfileYaml }}</pre>
        </gl-accordion-item>
      </gl-accordion>
    </template>

    <hr />

    <gl-button
      :disabled="someFieldEmpty"
      type="submit"
      variant="confirm"
      class="js-no-auto-disable"
      data-testid="api-fuzzing-configuration-submit-button"
      >{{ s__('APIFuzzing|Generate code snippet') }}</gl-button
    >
    <gl-button
      :href="securityConfigurationPath"
      data-testid="api-fuzzing-configuration-cancel-button"
      >{{ __('Cancel') }}</gl-button
    >

    <configuration-snippet-modal
      :ref="$options.CONFIGURATION_SNIPPET_MODAL_ID"
      :ci-yaml-edit-url="gitlabCiYamlEditPath"
      :yaml="configurationYaml"
      :redirect-param="$options.CODE_SNIPPET_SOURCE_API_FUZZING"
      scan-type="API Fuzzing"
    />
  </form>
</template>
