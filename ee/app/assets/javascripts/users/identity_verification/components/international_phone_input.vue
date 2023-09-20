<script>
import {
  GlForm,
  GlCollapsibleListbox,
  GlFormGroup,
  GlFormInputGroup,
  GlInputGroupText,
  GlFormInput,
  GlIcon,
  GlButton,
} from '@gitlab/ui';

import { createAlert } from '~/alert';
import { s__, n__ } from '~/locale';

import axios from '~/lib/utils/axios_utils';

import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import { validatePhoneNumber } from '../validations';

import {
  DEFAULT_COUNTRY,
  I18N_GENERIC_ERROR,
  UNKNOWN_TELESIGN_ERROR,
  RELATED_TO_BANNED_USER,
} from '../constants';

export default {
  name: 'InternationalPhoneInput',
  components: {
    GlForm,
    GlCollapsibleListbox,
    GlFormGroup,
    GlFormInputGroup,
    GlInputGroupText,
    GlFormInput,
    GlIcon,
    GlButton,
  },
  inject: {
    phoneNumber: {
      default: {
        country: DEFAULT_COUNTRY,
        number: '',
      },
    },
  },
  i18n: {
    phoneNumber: s__('IdentityVerification|Phone number'),
    country: s__('IdentityVerification|Country or region'),
    countryHelpText: s__('IdentityVerification|Select country or region'),
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
            value: this.phoneNumber.country || DEFAULT_COUNTRY,
            state: null,
            feedback: '',
          },
        },
      },
      countries: [],
      countriesSearchTerm: '',
      isLoading: false,
      alert: null,
      relatedToBannedUser: false,
    };
  },
  computed: {
    filteredCountries() {
      const searchTerm = this.countriesSearchTerm;
      const countriesArray = Object.values(this.countries);

      if (searchTerm) {
        const filteredCountries = countriesArray.filter(
          (country) =>
            country.name.toLowerCase().includes(searchTerm) ||
            country.value.toLowerCase().includes(searchTerm) ||
            country.internationalDialCode.includes(searchTerm),
        );

        return filteredCountries;
      }

      return Object.values(this.countries);
    },
    countryId() {
      return this.form.fields.country.value;
    },
    countryObject() {
      return this.countries[this.countryId];
    },
    internationalDialCode() {
      return this.countryObject?.internationalDialCode;
    },
    inputPhoneNumber() {
      return this.form.fields.phoneNumber.value;
    },
    isSubmitButtonDisabled() {
      return this.relatedToBannedUser || !this.form.fields.phoneNumber.state;
    },
    countryDropdownToggleText() {
      return this.countryObject?.text || this.$options.i18n.countryHelpText;
    },
    searchSummary() {
      return n__(
        'IdentityVerification|%d country found',
        'IdentityVerification|%d countries found',
        this.filteredCountries.length,
      );
    },
  },
  mounted() {
    if (this.inputPhoneNumber) {
      this.checkPhoneNumber();
    }
  },
  methods: {
    checkPhoneNumber() {
      const errorMessage = validatePhoneNumber(this.inputPhoneNumber);
      this.form.fields.phoneNumber.feedback = errorMessage;
      this.form.fields.phoneNumber.state = errorMessage.length <= 0;
    },
    sendVerificationCode() {
      this.isLoading = true;
      this.alert?.dismiss();

      const { countryId, internationalDialCode, inputPhoneNumber } = this;

      axios
        .post(this.phoneNumber.sendCodePath, {
          country: countryId,
          international_dial_code: internationalDialCode,
          phone_number: inputPhoneNumber,
        })
        .then(this.handleSendCodeResponse)
        .catch(this.handleError)
        .finally(() => {
          this.isLoading = false;
        });
    },
    handleSendCodeResponse() {
      const { countryId, internationalDialCode, inputPhoneNumber } = this;

      this.$emit('next', {
        country: countryId,
        internationalDialCode,
        number: inputPhoneNumber,
      });
    },
    handleError(error) {
      const reason = error.response?.data?.reason;
      if (reason === UNKNOWN_TELESIGN_ERROR) {
        this.$emit('skip-verification');
        return;
      }

      this.relatedToBannedUser = reason === RELATED_TO_BANNED_USER;

      this.alert = createAlert({
        message: error.response?.data?.message || this.$options.i18n.I18N_GENERIC_ERROR,
        captureError: true,
        error,
      });
    },
    onCountriesSearch(searchTerm) {
      this.countriesSearchTerm = searchTerm.trim().toLowerCase();
    },
  },
  apollo: {
    countries: {
      query: countriesQuery,
      update(data) {
        const nodes = data?.countries || [];

        return nodes.reduce((acc, { id, name, flag, internationalDialCode }) => {
          acc[id] = {
            value: id,
            text: `${flag} ${name} (+${internationalDialCode})`,
            name,
            internationalDialCode,
          };
          return acc;
        }, {});
      },
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="sendVerificationCode">
    <gl-form-group
      v-if="!$apollo.loading.countries"
      :label="$options.i18n.country"
      label-for="country"
      data-testid="country-form-group"
      :invalid-feedback="form.fields.country.feedback"
      :state="form.fields.country.state"
    >
      <gl-collapsible-listbox
        v-model="form.fields.country.value"
        :items="filteredCountries"
        fluid-width
        :toggle-text="countryDropdownToggleText"
        toggle-class="gl-inset-border-1-gray-400!"
        data-testid="country-form-select"
        searchable
        block
        @search="onCountriesSearch"
      >
        <template #search-summary-sr-only>
          {{ searchSummary }}
        </template>
      </gl-collapsible-listbox>
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.phoneNumber"
      label-for="phone_number"
      :state="form.fields.phoneNumber.state"
      :invalid-feedback="form.fields.phoneNumber.feedback"
      data-testid="phone-number-form-group"
    >
      <gl-form-input-group>
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
        <template #prepend>
          <gl-input-group-text> +{{ internationalDialCode }} </gl-input-group-text>
        </template>
      </gl-form-input-group>
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
      :disabled="isSubmitButtonDisabled"
      :loading="isLoading"
    >
      {{ $options.i18n.sendCode }}
    </gl-button>
  </gl-form>
</template>
