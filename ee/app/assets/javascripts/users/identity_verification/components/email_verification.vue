<script>
import { GlForm, GlFormGroup, GlFormInput, GlIcon, GlLink, GlSprintf, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  I18N_EMAIL_EMPTY_CODE,
  I18N_EMAIL_INVALID_CODE,
  I18N_GENERIC_ERROR,
  I18N_EMAIL_RESEND_SUCCESS,
} from '../constants';

const SUCCESS_RESPONSE = 'success';
const FAILURE_RESPONSE = 'failure';

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
  inject: ['email'],
  props: {
    isStandalone: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
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
        return I18N_EMAIL_EMPTY_CODE;
      }

      if (!this.verificationCode.match(/\d{6}/)) {
        return I18N_EMAIL_INVALID_CODE;
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
        .post(this.email.verifyPath, { code: this.verificationCode })
        .then(this.handleVerificationResponse)
        .catch(this.handleError);
    },
    resend() {
      axios
        .post(this.email.resendPath)
        .then(this.handleResendResponse)
        .catch(this.handleError)
        .finally(this.resetForm);
    },
    handleVerificationResponse(response) {
      if (response.data.status === undefined) {
        this.handleError();
      } else if (response.data.status === SUCCESS_RESPONSE) {
        this.$emit('completed');
      } else if (response.data.status === FAILURE_RESPONSE) {
        this.verifyError = response.data.message;
      }
    },
    handleResendResponse(response) {
      if (response.data.status === undefined) {
        this.handleError();
      } else if (response.data.status === SUCCESS_RESPONSE) {
        createAlert({
          message: I18N_EMAIL_RESEND_SUCCESS,
          variant: VARIANT_SUCCESS,
        });
      } else if (response.data.status === FAILURE_RESPONSE) {
        createAlert({ message: response.data.message });
      }
    },
    handleError(error) {
      createAlert({
        message: I18N_GENERIC_ERROR,
        captureError: true,
        error,
      });
    },
    resetForm() {
      this.verificationCode = '';
      this.submitted = false;
    },
  },
  i18n: {
    headerStandalone: s__(
      "IdentityVerification|For added security, you'll need to verify your identity.",
    ),
    header: s__("IdentityVerification|We've sent a verification code to %{email}"),
    code: s__('IdentityVerification|Verification code'),
    noCode: s__("IdentityVerification|Didn't receive a code?"),
    resend: s__('IdentityVerification|Send a new code'),
    verify: s__('IdentityVerification|Verify email address'),
  },
};
</script>
<template>
  <div>
    <p :class="{ 'gl-text-center': isStandalone }">
      <span v-if="isStandalone">{{ $options.i18n.headerStandalone }}</span>
      <gl-sprintf :message="$options.i18n.header">
        <template #email>
          <b>{{ email.obfuscated }}</b>
        </template>
      </gl-sprintf>
    </p>
    <div :class="{ 'gl-p-5 gl-border gl-rounded-base': isStandalone }">
      <gl-form @submit.prevent="verify">
        <gl-form-group
          :label="$options.i18n.code"
          label-for="verification_code"
          :state="isValidInput"
          :invalid-feedback="invalidFeedback"
        >
          <gl-form-input
            v-model="verificationCode"
            name="verification_code"
            :autofocus="true"
            autocomplete="one-time-code"
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
