<script>
import { GlForm, GlFormGroup, GlFormInput, GlIcon, GlLink, GlSprintf, GlButton } from '@gitlab/ui';
import { createAlert, VARIANT_SUCCESS } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { I18N_EMAIL_VERIFICATION, SUCCESS_RESPONSE, FAILURE_RESPONSE } from '../constants';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLink,
    GlSprintf,
    GlButton,
  },
  inject: ['emailObfuscated', 'emailVerifyPath', 'emailResendPath'],
  data() {
    return {
      verificationCode: '',
      submitted: false,
      verifyError: '',
    };
  },
  computed: {
    isValidInput() {
      return this.submitted ? !this.invalidFeedback : true;
    },
    invalidFeedback() {
      if (!this.submitted) {
        return '';
      }

      if (!this.verificationCode) {
        return this.$options.i18n.emptyCode;
      }

      if (!this.verificationCode.match(/\d{6}/)) {
        return this.$options.i18n.invalidCode;
      }

      return this.verifyError;
    },
  },
  watch: {
    verificationCode() {
      this.verifyError = '';
    },
  },
  methods: {
    verify() {
      this.submitted = true;

      if (!this.isValidInput) return;

      axios
        .post(this.emailVerifyPath, { code: this.verificationCode })
        .then(this.handleVerificationResponse)
        .catch(this.handleError);
    },
    resend() {
      axios
        .post(this.emailResendPath)
        .then(this.handleResendResponse)
        .catch(this.handleError)
        .finally(this.resetForm);
    },
    handleVerificationResponse(response) {
      if (response.data.status === SUCCESS_RESPONSE) {
        visitUrl(response.data.redirect_url);
      } else if (response.data.status === FAILURE_RESPONSE) {
        this.verifyError = response.data.message;
      }
    },
    handleResendResponse(response) {
      if (response.data.status === SUCCESS_RESPONSE) {
        createAlert({
          message: this.$options.i18n.resendSuccess,
          variant: VARIANT_SUCCESS,
        });
      } else if (response.data.status === FAILURE_RESPONSE) {
        createAlert({ message: response.data.message });
      }
    },
    handleError(error) {
      createAlert({
        message: this.$options.i18n.requestError,
        captureError: true,
        error,
      });
    },
    resetForm() {
      this.verificationCode = '';
      this.submitted = false;
    },
  },
  i18n: I18N_EMAIL_VERIFICATION,
};
</script>
<template>
  <div>
    <p class="gl-text-center">
      <gl-sprintf :message="$options.i18n.header">
        <template #email>
          <b>{{ emailObfuscated }}</b>
        </template>
      </gl-sprintf>
    </p>
    <div class="gl-p-5 gl-border gl-rounded-base">
      <gl-form @submit.prevent="verify">
        <gl-form-group
          :label="$options.i18n.verificationCode"
          label-for="verification_code"
          :state="isValidInput"
          :invalid-feedback="invalidFeedback"
        >
          <gl-form-input
            v-model="verificationCode"
            name="verification_code"
            :autofocus="true"
            autocomplete="off"
            inputmode="numeric"
            maxlength="6"
            :state="isValidInput"
            trim
          />
        </gl-form-group>
        <div class="gl-font-sm gl-text-secondary">
          <gl-icon name="information-o" :size="12" />
          {{ $options.i18n.noCode }}
          <gl-link class="gl-font-sm" @click="resend"> {{ $options.i18n.resend }}</gl-link>
        </div>
        <gl-button
          class="gl-mt-5 gl-mb-3"
          block
          variant="confirm"
          type="submit"
          :disabled="!isValidInput"
        >
          {{ $options.i18n.verify }}
        </gl-button>
      </gl-form>
    </div>
  </div>
</template>
