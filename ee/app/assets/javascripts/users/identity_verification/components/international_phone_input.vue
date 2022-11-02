<script>
import { GlFormGroup, GlFormInput, GlFormSelect, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import { validatePhoneNumber } from '../validations';
import { PHONE_NUMBER_LABEL, COUNTRY_LABEL } from '../constants';

export default {
  name: 'InternationalPhoneInput',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlIcon,
  },
  i18n: {
    PHONE_NUMBER_LABEL,
    COUNTRY_LABEL,
    infoText: s__(
      'IdentityVerification|You will receive a text containing a code. Standard charges may apply.',
    ),
  },
  data() {
    return {
      form: {
        fields: {
          phoneNumber: { value: '', state: null, feedback: '' },
          country: { value: 'US+1', state: null, feedback: '' },
        },
      },
      countries: [],
    };
  },
  computed: {
    countriesWithInternationalDialCode() {
      return this.countries.filter((country) => country.internationalDialCode);
    },
  },
  methods: {
    checkPhoneNumber() {
      const errorMessage = validatePhoneNumber(this.form.fields.phoneNumber.value);
      this.form.fields.phoneNumber.feedback = errorMessage;
      this.form.fields.phoneNumber.state = errorMessage.length <= 0;
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
  <div>
    <gl-form-group
      v-if="!$apollo.loading.countries"
      :label="$options.i18n.COUNTRY_LABEL"
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
      :label="$options.i18n.PHONE_NUMBER_LABEL"
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
        @blur="checkPhoneNumber"
      />
    </gl-form-group>

    <div class="gl-mt-3 gl-text-secondary gl-font-sm">
      <gl-icon name="information-o" :size="12" class="gl-mt-2" />
      <span>{{ $options.i18n.infoText }}</span>
    </div>
  </div>
</template>
