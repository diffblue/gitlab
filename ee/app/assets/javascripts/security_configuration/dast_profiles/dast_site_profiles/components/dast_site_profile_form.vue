<script>
import {
  GlFormGroup,
  GlFormInput,
  GlFormRadioGroup,
  GlFormText,
  GlFormTextarea,
  GlFormSelect,
  GlLink,
  GlSprintf,
  GlIcon,
  GlPopover,
} from '@gitlab/ui';
import { initFormField } from 'ee/security_configuration/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { serializeFormObject } from '~/lib/utils/forms';
import { __, s__, n__, sprintf } from '~/locale';
import BaseDastProfileForm from '../../components/base_dast_profile_form.vue';
import dastProfileFormMixin from '../../dast_profile_form_mixin';
import TooltipIcon from '../../dast_scanner_profiles/components/tooltip_icon.vue';
import {
  DAST_API_DOC_PATH_BASE,
  MAX_CHAR_LIMIT_EXCLUDED_URLS,
  MAX_CHAR_LIMIT_REQUEST_HEADERS,
  EXCLUDED_URLS_SEPARATOR,
  REDACTED_PASSWORD,
  REDACTED_REQUEST_HEADERS,
  TARGET_TYPES,
  SCAN_METHODS,
  DAST_PROXY_DOC_PATH_BASE,
} from '../constants';
import dastSiteProfileCreateMutation from '../graphql/dast_site_profile_create.mutation.graphql';
import dastSiteProfileUpdateMutation from '../graphql/dast_site_profile_update.mutation.graphql';
import DastSiteAuthSection from './dast_site_auth_section.vue';

export default {
  DAST_API_DOC_PATH: helpPagePath(DAST_API_DOC_PATH_BASE, {
    anchor: 'enable-dast-api-scanning',
  }),
  DAST_API_DOC_GRAPHQL_PATH: helpPagePath(DAST_API_DOC_PATH_BASE, {
    anchor: 'graphql-schema',
  }),
  DAST_PROXY_MASKING_PATH: helpPagePath(DAST_PROXY_DOC_PATH_BASE, {
    anchor: 'hide-sensitive-information',
  }),
  dastSiteProfileCreateMutation,
  dastSiteProfileUpdateMutation,
  i18n: {
    excludedUrls: {
      description: s__('DastProfiles|Enter URLs in a comma-separated list.'),
      tooltip: s__('DastProfiles|URLs to skip during the authenticated scan.'),
      placeholder: 'https://example.com/logout, https://example.com/send_mail',
    },
    requestHeaders: {
      label: s__('DastProfiles|Additional request headers (optional)'),
      description: s__(
        'DastProfiles|Enter a comma-separated list of request header names and values. DAST adds header to every request.',
      ),
      tooltip: s__(
        'DastProfiles|Headers will appear in vulnerability reports. %{linkStart}Only some headers are automatically masked%{linkEnd}.',
      ),
      // eslint-disable-next-line @gitlab/require-i18n-strings
      placeholder: 'Cache-control: no-cache, User-Agent: DAST/1.0',
    },
    scanMethod: {
      label: s__('DastProfiles|Scan method'),
      helpText: s__('DastProfiles|What does each method do?'),
      defaultOption: s__('DastProfiles|Choose a scan method'),
    },
    disabledProfileName: s__('DastProfiles|Profile in use and cannot be renamed'),
    dastApiDocsGraphQlHelpText: s__(
      'DastProfiles|Must allow introspection queries to request the API schema. %{linkStart}How do I enable introspection%{linkEnd}?',
    ),
  },
  name: 'DastSiteProfileForm',
  components: {
    BaseDastProfileForm,
    DastSiteAuthSection,
    GlFormGroup,
    GlFormInput,
    GlFormRadioGroup,
    GlFormText,
    GlFormTextarea,
    TooltipIcon,
    GlFormSelect,
    GlLink,
    GlSprintf,
    GlIcon,
    GlPopover,
  },
  mixins: [dastProfileFormMixin()],
  data() {
    const {
      name = '',
      profileName = '',
      targetUrl = '',
      excludedUrls = [],
      requestHeaders = '',
      auth = {},
      targetType = TARGET_TYPES.WEBSITE.value,
      scanMethod = null,
      scanFilePath = '',
    } = this.profile;

    const form = {
      state: false,
      showValidation: false,
      fields: {
        profileName: initFormField({ value: name || profileName }),
        targetUrl: initFormField({ value: targetUrl }),
        excludedUrls: initFormField({
          value: (excludedUrls || []).join(EXCLUDED_URLS_SEPARATOR),
          required: false,
          skipValidation: true,
        }),
        requestHeaders: initFormField({
          value: requestHeaders || '',
          required: false,
          skipValidation: true,
        }),
        targetType: initFormField({ value: targetType, skipValidation: true }),
        scanMethod: initFormField({ value: scanMethod, skipValidation: true }),
        scanFilePath: initFormField({ value: scanFilePath, skipValidation: true }),
      },
    };

    return {
      form,
      authSection: { fields: auth },
      initialFormValues: serializeFormObject(form.fields),
      tokenId: null,
      token: null,
      targetTypesOptions: Object.values(TARGET_TYPES),
      showAPIFilePath: false,
      scanMethodOptions: Object.values(SCAN_METHODS),
      SCAN_METHODS,
    };
  },
  computed: {
    i18n() {
      const { isEdit } = this;
      return {
        title: isEdit
          ? s__('DastProfiles|Edit site profile')
          : s__('DastProfiles|New site profile'),
        errorMessage: isEdit
          ? s__('DastProfiles|Could not update the site profile. Please try again.')
          : s__('DastProfiles|Could not create the site profile. Please try again.'),
        excludedUrls: {
          label: this.isTargetAPI
            ? s__('DastProfiles|Excluded paths (optional)')
            : s__('DastProfiles|Excluded URLs (optional)'),
        },
        targetUrl: {
          label: this.isTargetAPI
            ? s__('DastProfiles|API endpoint URL')
            : s__('DastProfiles|Target URL'),
        },
      };
    },
    parsedExcludedUrls() {
      const { value } = this.form.fields.excludedUrls;
      if (!value) {
        return [];
      }
      return value.split(EXCLUDED_URLS_SEPARATOR).map((url) => url.trim());
    },
    serializedAuthFields() {
      const authFields = { ...this.authSection.fields };
      // not to send password value if unchanged
      if (authFields.password === REDACTED_PASSWORD) {
        delete authFields.password;
      }
      if (!authFields.submitField) {
        authFields.submitField = '';
      }
      return authFields;
    },
    isGraphQlMethod() {
      return this.form.fields.scanMethod.value === SCAN_METHODS.GRAPHQL.value;
    },
    isTargetAPI() {
      return this.form.fields.targetType.value === TARGET_TYPES.API.value;
    },
    selectedScanMethod() {
      return SCAN_METHODS[this.form.fields.scanMethod.value];
    },
    isAuthEnabled() {
      return this.authSection.fields.enabled;
    },
    isSubmitBlocked() {
      return !this.form.state || (this.isAuthEnabled && !this.authSection.state);
    },
    mutationVariables() {
      const {
        profileName,
        targetUrl,
        targetType,
        requestHeaders,
        scanMethod,
        scanFilePath,
      } = serializeFormObject(this.form.fields);

      return {
        ...(this.isEdit ? { id: this.profile.id } : { fullPath: this.projectFullPath }),
        profileName,
        targetUrl,
        targetType,
        auth: this.serializedAuthFields,
        excludedUrls: this.parsedExcludedUrls,
        ...(requestHeaders !== REDACTED_REQUEST_HEADERS && {
          requestHeaders,
        }),
        ...(this.isTargetAPI && { scanMethod, scanFilePath }),
      };
    },
  },
  methods: {
    getCharacterLimitText(value, limit) {
      return value.length
        ? n__('%d character remaining', '%d characters remaining', limit - value.length)
        : sprintf(__('Maximum character limit - %{limit}'), {
            limit,
          });
    },
  },
  MAX_CHAR_LIMIT_EXCLUDED_URLS,
  MAX_CHAR_LIMIT_REQUEST_HEADERS,
};
</script>

<template>
  <base-dast-profile-form
    v-bind="$attrs"
    :profile="profile"
    :mutation="
      isEdit ? $options.dastSiteProfileUpdateMutation : $options.dastSiteProfileCreateMutation
    "
    :mutation-type="isEdit ? 'dastSiteProfileUpdate' : 'dastSiteProfileCreate'"
    :mutation-variables="mutationVariables"
    :form-touched="formTouched"
    :is-policy-profile="isPolicyProfile"
    :block-submit="isSubmitBlocked"
    :show-header="!stacked"
    @submit="form.showValidation = true"
    v-on="$listeners"
  >
    <template #title>
      {{ i18n.title }}
    </template>

    <template #policy-profile-notice>
      {{
        s__(
          'DastProfiles|This site profile is currently being used by a policy. To make edits you must remove it from the active policy.',
        )
      }}
    </template>

    <template #error-message>{{ i18n.errorMessage }}</template>

    <gl-form-group class="gl-mb-0" data-testid="dast-site-parent-group" :disabled="isPolicyProfile">
      <gl-form-group :invalid-feedback="form.fields.profileName.feedback">
        <template #label>
          {{ s__('DastProfiles|Profile name') }}
          <tooltip-icon v-if="isProfileInUse" :title="$options.i18n.disabledProfileName" />
        </template>
        <gl-form-input
          v-model="form.fields.profileName.value"
          v-validation:[form.showValidation]
          :disabled="isProfileInUse"
          name="profileName"
          class="gl-max-w-62"
          data-testid="profile-name-input"
          type="text"
          required
          :state="form.fields.profileName.state"
        />
      </gl-form-group>

      <gl-form-group :label="s__('DastProfiles|Site type')">
        <gl-form-radio-group
          v-model="form.fields.targetType.value"
          :options="targetTypesOptions"
          data-testid="site-type-option"
        />
      </gl-form-group>

      <gl-form-group
        data-testid="target-url-input-group"
        :invalid-feedback="form.fields.targetUrl.feedback"
        :label="i18n.targetUrl.label"
      >
        <gl-form-input
          v-model="form.fields.targetUrl.value"
          v-validation:[form.showValidation]
          name="targetUrl"
          class="gl-max-w-62"
          data-testid="target-url-input"
          required
          type="url"
          :state="form.fields.targetUrl.state"
        />
      </gl-form-group>

      <gl-form-group
        v-if="isTargetAPI"
        id="scan-method-popover-container"
        :label="$options.i18n.scanMethod.label"
      >
        <gl-form-select
          v-model="form.fields.scanMethod.value"
          v-validation:[form.showValidation]
          :options="scanMethodOptions"
          name="scanMethod"
          class="gl-max-w-62"
          data-testid="scan-method-select-input"
          :state="form.fields.scanMethod.state"
          required
        >
          <template #first>
            <option :value="null" disabled>{{ $options.i18n.scanMethod.defaultOption }}</option>
          </template>
        </gl-form-select>

        <gl-form-text
          ><gl-link :href="$options.DAST_API_DOC_PATH" target="_blank">{{
            $options.i18n.scanMethod.helpText
          }}</gl-link></gl-form-text
        >

        <gl-form-group
          v-if="selectedScanMethod"
          class="gl-mt-5"
          :label="selectedScanMethod.inputLabel"
          :invalid-feedback="form.fields.scanFilePath.feedback"
        >
          <gl-form-input
            v-model="form.fields.scanFilePath.value"
            v-validation:[form.showValidation]
            name="scanFilePath"
            class="gl-max-w-62"
            data-testid="scan-file-path-input"
            type="text"
            :placeholder="selectedScanMethod.placeholder"
            required
            :state="form.fields.scanFilePath.state"
          />

          <gl-form-text v-if="isGraphQlMethod" data-testid="graphql-help-text" class="gl-max-w-62">
            <gl-sprintf :message="$options.i18n.dastApiDocsGraphQlHelpText">
              <template #link="{ content }">
                <gl-link :href="$options.DAST_API_DOC_GRAPHQL_PATH" target="_blank">{{
                  content
                }}</gl-link>
              </template>
            </gl-sprintf>
          </gl-form-text>
        </gl-form-group>
      </gl-form-group>

      <div class="row">
        <gl-form-group
          :label="i18n.excludedUrls.label"
          :invalid-feedback="form.fields.excludedUrls.feedback"
          :class="{ 'col-md-6': !stacked, 'col-md-12': stacked }"
        >
          <template #label>
            {{ i18n.excludedUrls.label }}
            <tooltip-icon :title="$options.i18n.excludedUrls.tooltip" />
            <gl-form-text class="gl-mt-3">{{
              $options.i18n.excludedUrls.description
            }}</gl-form-text>
          </template>
          <gl-form-textarea
            v-model="form.fields.excludedUrls.value"
            :maxlength="$options.MAX_CHAR_LIMIT_EXCLUDED_URLS"
            :placeholder="$options.i18n.excludedUrls.placeholder"
            :no-resize="false"
            data-testid="excluded-urls-input"
          />
          <gl-form-text>{{
            getCharacterLimitText(
              form.fields.excludedUrls.value,
              $options.MAX_CHAR_LIMIT_EXCLUDED_URLS,
            )
          }}</gl-form-text>
        </gl-form-group>

        <gl-form-group
          :invalid-feedback="form.fields.requestHeaders.feedback"
          :class="{ 'col-md-6': !stacked, 'col-md-12': stacked }"
        >
          <template #label>
            {{ $options.i18n.requestHeaders.label }}
            <gl-icon
              id="request-headers-info"
              name="information-o"
              class="gl-vertical-align-text-bottom gl-text-gray-400 gl-ml-2"
            />
            <gl-popover target="request-headers-info" placement="top" triggers="focus hover"
              ><gl-sprintf :message="$options.i18n.requestHeaders.tooltip">
                <template #link="{ content }">
                  <gl-link
                    class="gl-font-sm"
                    :href="$options.DAST_PROXY_MASKING_PATH"
                    target="_blank"
                    >{{ content }}</gl-link
                  >
                </template>
              </gl-sprintf>
            </gl-popover>
            <gl-form-text class="gl-mt-3">{{
              $options.i18n.requestHeaders.description
            }}</gl-form-text>
          </template>
          <gl-form-textarea
            v-model="form.fields.requestHeaders.value"
            :maxlength="$options.MAX_CHAR_LIMIT_REQUEST_HEADERS"
            :placeholder="$options.i18n.requestHeaders.placeholder"
            :no-resize="false"
            data-testid="request-headers-input"
          />
          <gl-form-text>{{
            getCharacterLimitText(
              form.fields.requestHeaders.value,
              $options.MAX_CHAR_LIMIT_REQUEST_HEADERS,
            )
          }}</gl-form-text>
        </gl-form-group>
      </div>
    </gl-form-group>

    <dast-site-auth-section
      v-model="authSection"
      class="gl-mt-n3"
      :is-target-api="isTargetAPI"
      :disabled="isPolicyProfile"
      :show-validation="form.showValidation"
      :is-edit-mode="isEdit"
      :stacked="stacked"
    />
  </base-dast-profile-form>
</template>
