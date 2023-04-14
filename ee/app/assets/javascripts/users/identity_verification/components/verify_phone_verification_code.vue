<script>
import { GlForm, GlFormGroup, GlFormInput, GlIcon, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';

import { validateVerificationCode } from '../validations';

export default {
  name: 'VerifyPhoneVerificationCode',
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlSprintf,
    GlLink,
    GlButton,
  },
  i18n: {
    verificationCode: s__('IdentityVerification|Verification code'),
    helper: s__("IdentityVerification|We've sent a verification code to +%{phoneNumber}"),
    resendCode: s__(
      "IdentityVerification|Didn't receive a code? %{linkStart}Send a new code%{linkEnd}",
    ),
    resendSuccess: s__('IdentityVerification|We sent a new code to +%{phoneNumber}'),
    back: s__('IdentityVerification|%{linkStart}Enter a new phone number%{linkEnd}'),
    verify: s__('IdentityVerification|Verify phone number'),
  },
  inject: ['phoneNumber'],
  props: {
    latestPhoneNumber: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
  },
  data() {
    return {
      form: {
        fields: {
          verificationCode: { value: '', state: null, feedback: '' },
        },
      },
      isLoading: false,
      alert: null,
    };
  },
  computed: {
    labelDescription() {
      return sprintf(this.$options.i18n.helper, {
        phoneNumber: this.internationalPhoneNumber,
      });
    },
    internationalPhoneNumber() {
      return `${this.latestPhoneNumber.internationalDialCode}${this.latestPhoneNumber.number}`;
    },
  },
  methods: {
    checkVerificationCode() {
      const errorMessage = validateVerificationCode(this.form.fields.verificationCode.value);
      this.form.fields.verificationCode.feedback = errorMessage;
      this.form.fields.verificationCode.state = errorMessage.length <= 0;
    },
    verifyCode() {
      this.isLoading = true;
      this.alert?.dismiss();

      axios
        .post(this.phoneNumber.verifyCodePath, {
          verification_code: this.form.fields.verificationCode.value,
        })
        .then(this.handleVerifySuccessResponse)
        .catch(this.handleError)
        .finally(() => {
          this.isLoading = false;
        });
    },
    handleVerifySuccessResponse() {
      this.$emit('verified');
    },
    resendCode() {
      this.isLoading = true;
      this.alert?.dismiss();

      axios
        .post(this.phoneNumber.sendCodePath, {
          country: this.latestPhoneNumber.country,
          international_dial_code: this.latestPhoneNumber.internationalDialCode,
          phone_number: this.latestPhoneNumber.number,
        })
        .then(this.handleResendCodeResponse)
        .catch(this.handleError)
        .finally(() => {
          this.isLoading = false;
        });
    },
    handleResendCodeResponse() {
      this.alert = createAlert({
        message: sprintf(this.$options.i18n.resendSuccess, {
          phoneNumber: this.internationalPhoneNumber,
        }),
        variant: VARIANT_SUCCESS,
      });
    },
    handleError(error) {
      if (error.response?.data?.reason === 'unknown_telesign_error') {
        this.$emit('verified');
        return;
      }

      this.alert = createAlert({
        message: error.response?.data?.message || this.$options.i18n.I18N_GENERIC_ERROR,
        captureError: true,
        error,
      });
    },
    goBack() {
      this.resetForm();
      this.$emit('back');
    },
    resetForm() {
      this.form.fields.verificationCode = { value: '', state: null, feedback: '' };
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="verifyCode">
    <gl-form-group
      :label="$options.i18n.verificationCode"
      :label-description="labelDescription"
      label-for="verification_code"
      :state="form.fields.verificationCode.state"
      :invalid-feedback="form.fields.verificationCode.feedback"
      data-testid="verification-code-form-group"
      class="gl-mb-2"
    >
      <gl-form-input
        v-model="form.fields.verificationCode.value"
        type="number"
        name="verification_code"
        :state="form.fields.verificationCode.state"
        trim
        autocomplete="one-time-code"
        data-testid="verification-code-form-input"
        class="gl-number-as-text-input"
        @input="checkVerificationCode"
      />
    </gl-form-group>

    <div class="gl-font-sm gl-text-secondary">
      <gl-icon name="information-o" :size="12" class="gl-mt-2" />
      <gl-sprintf :message="$options.i18n.resendCode">
        <template #link="{ content }">
          <gl-link class="gl-font-sm" data-testid="resend-code-link" @click="resendCode">
            {{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </div>

    <gl-button
      type="submit"
      variant="confirm"
      class="gl-w-full! gl-mt-5"
      :disabled="!form.fields.verificationCode.state"
      :loading="isLoading"
    >
      {{ $options.i18n.verify }}
    </gl-button>

    <div class="gl-mt-4 gl-font-sm gl-text-secondary">
      <gl-sprintf :message="$options.i18n.back">
        <template #link="{ content }">
          <gl-link class="gl-font-sm" @click="goBack">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </div>
  </gl-form>
</template>
