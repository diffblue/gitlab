<script>
import { GlForm, GlFormGroup, GlFormInput, GlFormSelect, GlIcon, GlButton } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { s__ } from '~/locale';

import axios from '~/lib/utils/axios_utils';

import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import { validatePhoneNumber } from '../validations';

import { DEFAULT_COUNTRY, DEFAULT_INTERNATIONAL_DIAL_CODE, I18N_GENERIC_ERROR } from '../constants';

export default {
  name: 'InternationalPhoneInput',
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlIcon,
    GlButton,
  },
  inject: {
    phoneNumber: {
      default: {
        country: DEFAULT_COUNTRY,
        internationalDialCode: DEFAULT_INTERNATIONAL_DIAL_CODE,
        number: '',
      },
    },
  },
  i18n: {
    phoneNumber: s__('IdentityVerification|Phone number'),
    dialCode: s__('IdentityVerification|International dial code'),
    infoText: s__(
      'IdentityVerification|You will receive a text containing a code. Standard charges may apply.',
    ),
    success: s__("IdentityVerification|We've sent a verification code to +%{phoneNumber}"),
    sendCode: s__('IdentityVerification|Send code'),
    I18N_GENERIC_ERROR,
  },
  data() {
    return {
      form: {
        fields: {
          phoneNumber: {
            value: this.phoneNumber.number,
            state: null,
            feedback: '',
          },
          country: {
            value: `${this.phoneNumber.country || DEFAULT_COUNTRY}+${
              this.phoneNumber.internationalDialCode || DEFAULT_INTERNATIONAL_DIAL_CODE
            }`,
            state: null,
            feedback: '',
          },
        },
      },
      countries: [],
      isLoading: false,
      alert: null,
    };
  },
  computed: {
    countriesWithInternationalDialCode() {
      return this.countries.filter((country) => country.internationalDialCode);
    },
    internationalPhoneNumber() {
      const internationalDialCode = this.countryAndDialCode[1];
      const phoneNumber = this.number;

      return `${internationalDialCode}${phoneNumber}`;
    },
    countryAndDialCode() {
      return this.form.fields.country.value.split('+');
    },
    number() {
      return this.form.fields.phoneNumber.value;
    },
  },
  mounted() {
    if (this.number) {
      this.checkPhoneNumber();
    }
  },
  methods: {
    checkPhoneNumber() {
      const errorMessage = validatePhoneNumber(this.number);
      this.form.fields.phoneNumber.feedback = errorMessage;
      this.form.fields.phoneNumber.state = errorMessage.length <= 0;
    },
    sendVerificationCode() {
      this.isLoading = true;
      this.alert?.dismiss();

      const [country, internationalDialCode] = this.countryAndDialCode;
      const { number } = this;

      axios
        .post(this.phoneNumber.sendCodePath, {
          country,
          international_dial_code: internationalDialCode,
          phone_number: number,
        })
        .then(this.handleSendCodeResponse)
        .catch(this.handleError)
        .finally(() => {
          this.isLoading = false;
        });
    },
    handleSendCodeResponse() {
      const [country, internationalDialCode] = this.countryAndDialCode;
      const { number } = this;

      this.$emit('next', {
        country,
        internationalDialCode,
        number,
      });
    },
    handleError(error) {
      if (error.response?.data?.reason === 'unknown_telesign_error') {
        this.$emit('skip-verification');
        return;
      }

      this.alert = createAlert({
        message: error.response?.data?.message || this.$options.i18n.I18N_GENERIC_ERROR,
        captureError: true,
        error,
      });
    },
  },
  apollo: {
    countries: {
      query: countriesQuery,
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="sendVerificationCode">
    <gl-form-group
      v-if="!$apollo.loading.countries"
      :label="$options.i18n.dialCode"
      label-for="country"
      data-testid="country-form-group"
    >
      <gl-form-select
        id="country"
        v-model="form.fields.country.value"
        name="country"
        required
        data-testid="country-form-select"
      >
        <option
          v-for="country in countriesWithInternationalDialCode"
          :key="country.id"
          :value="`${country.id}+${country.internationalDialCode}`"
        >
          <span>{{ country.flag }} {{ country.name }}</span>
          <span>+{{ country.internationalDialCode }}</span>
        </option>
      </gl-form-select>
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.phoneNumber"
      label-for="phone_number"
      :state="form.fields.phoneNumber.state"
      :invalid-feedback="form.fields.phoneNumber.feedback"
      data-testid="phone-number-form-group"
    >
      <gl-form-input
        v-model="form.fields.phoneNumber.value"
        type="tel"
        name="phone_number"
        :state="form.fields.phoneNumber.state"
        trim
        autocomplete="off"
        data-testid="phone-number-form-input"
        debounce="250"
        @input="checkPhoneNumber"
      />
    </gl-form-group>

    <div class="gl-mt-3 gl-text-secondary gl-font-sm">
      <gl-icon name="information-o" :size="12" class="gl-mt-2" />
      <span>{{ $options.i18n.infoText }}</span>
    </div>

    <gl-button
      variant="confirm"
      type="submit"
      block
      class="gl-mt-5"
      :disabled="!form.fields.phoneNumber.state"
      :loading="isLoading"
    >
      {{ $options.i18n.sendCode }}
    </gl-button>
  </gl-form>
</template>
