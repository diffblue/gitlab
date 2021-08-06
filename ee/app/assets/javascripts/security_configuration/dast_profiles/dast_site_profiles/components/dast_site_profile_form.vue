<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlModal,
  GlFormTextarea,
  GlFormText,
  GlFormRadioGroup,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { isEqual } from 'lodash';
import { initFormField } from 'ee/security_configuration/utils';
import { serializeFormObject } from '~/lib/utils/forms';
import { __, s__, n__, sprintf } from '~/locale';
import validation from '~/vue_shared/directives/validation';
import tooltipIcon from '../../dast_scanner_profiles/components/tooltip_icon.vue';
import {
  MAX_CHAR_LIMIT_EXCLUDED_URLS,
  MAX_CHAR_LIMIT_REQUEST_HEADERS,
  EXCLUDED_URLS_SEPARATOR,
  REDACTED_PASSWORD,
  REDACTED_REQUEST_HEADERS,
  TARGET_TYPES,
} from '../constants';
import dastSiteProfileCreateMutation from '../graphql/dast_site_profile_create.mutation.graphql';
import dastSiteProfileUpdateMutation from '../graphql/dast_site_profile_update.mutation.graphql';
import DastSiteAuthSection from './dast_site_auth_section.vue';

export default {
  name: 'DastSiteProfileForm',
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlModal,
    GlFormTextarea,
    DastSiteAuthSection,
    GlFormText,
    tooltipIcon,
    GlFormRadioGroup,
  },
  directives: {
    validation: validation(),
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    siteProfile: {
      type: Object,
      required: false,
      default: null,
    },
    showHeader: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    const {
      name = '',
      targetUrl = '',
      excludedUrls = [],
      requestHeaders = '',
      auth = {},
      targetType = TARGET_TYPES.WEBSITE.value,
    } = this.siteProfile || {};

    const form = {
      state: false,
      showValidation: false,
      fields: {
        profileName: initFormField({ value: name }),
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
      },
    };

    return {
      form,
      authSection: { fields: auth },
      initialFormValues: serializeFormObject(form.fields),
      isLoading: false,
      hasAlert: false,
      tokenId: null,
      token: null,
      errorMessage: '',
      errors: [],
      targetTypesOptions: Object.values(TARGET_TYPES),
    };
  },
  computed: {
    isEdit() {
      return Boolean(this.siteProfile?.id);
    },
    hasRequestHeaders() {
      return Boolean(this.siteProfile?.requestHeaders);
    },
    i18n() {
      const { isEdit } = this;
      return {
        title: isEdit
          ? s__('DastProfiles|Edit site profile')
          : s__('DastProfiles|New site profile'),
        errorMessage: isEdit
          ? s__('DastProfiles|Could not update the site profile. Please try again.')
          : s__('DastProfiles|Could not create the site profile. Please try again.'),
        modal: {
          title: isEdit
            ? s__('DastProfiles|Do you want to discard your changes?')
            : s__('DastProfiles|Do you want to discard this site profile?'),
          okTitle: __('Discard'),
          cancelTitle: __('Cancel'),
        },
        excludedUrls: {
          label: s__('DastProfiles|Excluded URLs (Optional)'),
          description: s__('DastProfiles|Enter URLs in a comma-separated list.'),
          tooltip: s__('DastProfiles|URLs to skip during the authenticated scan.'),
          placeholder: 'https://example.com/logout, https://example.com/send_mail',
        },
        requestHeaders: {
          label: s__('DastProfiles|Additional request headers (Optional)'),
          description: s__('DastProfiles|Enter headers in a comma-separated list.'),
          tooltip: s__(
            'DastProfiles|Request header names and values. Headers are added to every request made by DAST.',
          ),
          // eslint-disable-next-line @gitlab/require-i18n-strings
          placeholder: 'Cache-control: no-cache, User-Agent: DAST/1.0',
        },
      };
    },
    formTouched() {
      return !isEqual(serializeFormObject(this.form.fields), this.initialFormValues);
    },
    isPolicyProfile() {
      return Boolean(this.siteProfile?.referencedInSecurityPolicies?.length);
    },
    parsedExcludedUrls() {
      return this.form.fields.excludedUrls.value
        .split(EXCLUDED_URLS_SEPARATOR)
        .map((url) => url.trim());
    },
    serializedAuthFields() {
      const authFields = this.authSection.fields;
      // not to send password value if unchanged
      if (authFields.password === REDACTED_PASSWORD) {
        delete authFields.password;
      }
      return authFields;
    },
    isTargetAPI() {
      return this.form.fields.targetType.value === TARGET_TYPES.API.value;
    },
  },
  methods: {
    onSubmit() {
      const isAuthEnabled = this.authSection.fields.enabled && !this.isTargetAPI;

      this.form.showValidation = true;

      if (!this.form.state || (isAuthEnabled && !this.authSection.state)) {
        return;
      }

      this.isLoading = true;
      this.hideErrors();
      const { errorMessage } = this.i18n;

      const {
        profileName,
        targetUrl,
        targetType,
        requestHeaders,
        excludedUrls,
      } = serializeFormObject(this.form.fields);

      const variables = {
        input: {
          fullPath: this.fullPath,
          ...(this.isEdit ? { id: this.siteProfile.id } : {}),
          profileName,
          targetUrl,
          targetType,
          ...(!this.isTargetAPI && { auth: this.serializedAuthFields }),
          ...(excludedUrls && {
            excludedUrls: this.parsedExcludedUrls,
          }),
          ...(requestHeaders !== REDACTED_REQUEST_HEADERS && {
            requestHeaders,
          }),
        },
      };

      this.$apollo
        .mutate({
          mutation: this.isEdit ? dastSiteProfileUpdateMutation : dastSiteProfileCreateMutation,
          variables,
        })
        .then(
          ({
            data: {
              [this.isEdit ? 'dastSiteProfileUpdate' : 'dastSiteProfileCreate']: {
                id,
                errors = [],
              },
            },
          }) => {
            if (errors.length > 0) {
              this.showErrors({ message: errorMessage, errors });
              this.isLoading = false;
            } else {
              this.$emit('success', {
                id,
              });
            }
          },
        )
        .catch((exception) => {
          this.showErrors({ message: errorMessage });
          this.captureException(exception);
          this.isLoading = false;
        });
    },
    onCancelClicked() {
      if (!this.formTouched) {
        this.discard();
      } else {
        this.$refs[this.$options.modalId].show();
      }
    },
    discard() {
      this.$emit('cancel');
    },
    captureException(exception) {
      Sentry.captureException(exception);
    },
    showErrors({ message, errors = [] }) {
      this.errorMessage = message;
      this.errors = errors;
      this.hasAlert = true;
    },
    hideErrors() {
      this.errorMessage = '';
      this.errors = [];
      this.hasAlert = false;
    },
    getCharacterLimitText(value, limit) {
      return value.length
        ? n__('%d character remaining', '%d characters remaining', limit - value.length)
        : sprintf(__('Maximum character limit - %{limit}'), {
            limit,
          });
    },
  },
  modalId: 'deleteDastProfileModal',
  MAX_CHAR_LIMIT_EXCLUDED_URLS,
  MAX_CHAR_LIMIT_REQUEST_HEADERS,
};
</script>

<template>
  <gl-form novalidate @submit.prevent="onSubmit">
    <h2 v-if="showHeader" class="gl-mb-6">
      {{ i18n.title }}
    </h2>

    <gl-alert
      v-if="isPolicyProfile"
      data-testid="dast-policy-site-profile-form-alert"
      variant="info"
      class="gl-mb-5"
      :dismissible="false"
    >
      {{
        s__(
          'DastProfiles|This site profile is currently being used by a policy. To make edits you must remove it from the active policy.',
        )
      }}
    </gl-alert>

    <gl-alert
      v-if="hasAlert"
      variant="danger"
      class="gl-mb-5"
      data-testid="dast-site-profile-form-alert"
      @dismiss="hideErrors"
    >
      {{ errorMessage }}
      <ul v-if="errors.length" class="gl-mt-3 gl-mb-0">
        <li v-for="error in errors" :key="error" v-text="error"></li>
      </ul>
    </gl-alert>

    <gl-form-group data-testid="dast-site-parent-group" :disabled="isPolicyProfile">
      <gl-form-group
        :label="s__('DastProfiles|Profile name')"
        :invalid-feedback="form.fields.profileName.feedback"
      >
        <gl-form-input
          v-model="form.fields.profileName.value"
          v-validation:[form.showValidation]
          name="profileName"
          class="mw-460"
          data-testid="profile-name-input"
          type="text"
          required
          :state="form.fields.profileName.state"
        />
      </gl-form-group>

      <hr class="gl-border-gray-100" />

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
        :label="s__('DastProfiles|Target URL')"
      >
        <gl-form-input
          v-model="form.fields.targetUrl.value"
          v-validation:[form.showValidation]
          name="targetUrl"
          class="mw-460"
          data-testid="target-url-input"
          required
          type="url"
          :state="form.fields.targetUrl.state"
        />
      </gl-form-group>

      <div class="row">
        <gl-form-group
          :label="s__('DastProfiles|Excluded URLs (Optional)')"
          :invalid-feedback="form.fields.excludedUrls.feedback"
          class="col-md-6"
        >
          <template #label>
            {{ i18n.excludedUrls.label }}
            <tooltip-icon :title="i18n.excludedUrls.tooltip" />
            <gl-form-text class="gl-mt-3">{{ i18n.excludedUrls.description }}</gl-form-text>
          </template>
          <gl-form-textarea
            v-model="form.fields.excludedUrls.value"
            :maxlength="$options.MAX_CHAR_LIMIT_EXCLUDED_URLS"
            :placeholder="i18n.excludedUrls.placeholder"
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

        <gl-form-group :invalid-feedback="form.fields.requestHeaders.feedback" class="col-md-6">
          <template #label>
            {{ i18n.requestHeaders.label }}
            <tooltip-icon :title="i18n.requestHeaders.tooltip" />
            <gl-form-text class="gl-mt-3">{{ i18n.requestHeaders.description }}</gl-form-text>
          </template>
          <gl-form-textarea
            v-model="form.fields.requestHeaders.value"
            :maxlength="$options.MAX_CHAR_LIMIT_REQUEST_HEADERS"
            :placeholder="i18n.requestHeaders.placeholder"
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
      v-if="!isTargetAPI"
      v-model="authSection"
      :disabled="isPolicyProfile"
      :show-validation="form.showValidation"
      :is-edit-mode="isEdit"
    />

    <hr class="gl-border-gray-100" />

    <gl-button
      :disabled="isPolicyProfile"
      type="submit"
      variant="confirm"
      class="js-no-auto-disable"
      data-testid="dast-site-profile-form-submit-button"
      :loading="isLoading"
    >
      {{ s__('DastProfiles|Save profile') }}
    </gl-button>
    <gl-button
      class="gl-ml-2"
      data-testid="dast-site-profile-form-cancel-button"
      @click="onCancelClicked"
    >
      {{ __('Cancel') }}
    </gl-button>

    <gl-modal
      :ref="$options.modalId"
      :modal-id="$options.modalId"
      :title="i18n.modal.title"
      :ok-title="i18n.modal.okTitle"
      :cancel-title="i18n.modal.cancelTitle"
      ok-variant="danger"
      body-class="gl-display-none"
      data-testid="dast-site-profile-form-cancel-modal"
      @ok="discard()"
    />
  </gl-form>
</template>
