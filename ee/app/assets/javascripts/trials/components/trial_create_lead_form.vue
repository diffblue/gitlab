<script>
import { GlForm, GlButton, GlFormGroup, GlFormInput, GlFormSelect } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { trackSaasTrialSubmit } from '~/google_tag_manager';
import {
  LEADS_COMPANY_NAME_LABEL,
  LEADS_COMPANY_SIZE_LABEL,
  LEADS_COUNTRY_LABEL,
  LEADS_COUNTRY_PROMPT,
  LEADS_FIRST_NAME_LABEL,
  LEADS_LAST_NAME_LABEL,
  LEADS_PHONE_NUMBER_LABEL,
  companySizes,
} from 'ee/vue_shared/leads/constants';
import {
  TRIAL_COMPANY_SIZE_PROMPT,
  TRIAL_FORM_SUBMIT_TEXT,
  TRIAL_PHONE_DESCRIPTION,
} from '../constants';

export default {
  name: 'TrialCreateLeadForm',
  csrf,
  components: {
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
  },
  directives: {
    autofocusonshow,
  },
  inject: ['user', 'submitPath'],
  data() {
    return {
      ...this.user,
      countries: [],
    };
  },
  apollo: {
    countries: {
      query: countriesQuery,
    },
  },
  computed: {
    companySizeOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.companySizeSelectPrompt,
          id: null,
        },
        ...companySizes,
      ];
    },
    countryOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.countrySelectPrompt,
          id: null,
        },
        ...this.countries,
      ];
    },
  },
  methods: {
    onSubmit() {
      trackSaasTrialSubmit();
    },
  },
  i18n: {
    firstNameLabel: LEADS_FIRST_NAME_LABEL,
    lastNameLabel: LEADS_LAST_NAME_LABEL,
    companyNameLabel: LEADS_COMPANY_NAME_LABEL,
    companySizeLabel: LEADS_COMPANY_SIZE_LABEL,
    phoneNumberLabel: LEADS_PHONE_NUMBER_LABEL,
    countryLabel: LEADS_COUNTRY_LABEL,
    countrySelectPrompt: LEADS_COUNTRY_PROMPT,
    formSubmitText: TRIAL_FORM_SUBMIT_TEXT,
    companySizeSelectPrompt: TRIAL_COMPANY_SIZE_PROMPT,
    phoneNumberDescription: TRIAL_PHONE_DESCRIPTION,
  },
};
</script>

<template>
  <gl-form :action="submitPath" method="post" @submit="onSubmit">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-mt-5">
      <gl-form-group
        :label="$options.i18n.firstNameLabel"
        label-size="sm"
        label-for="first_name"
        class="gl-mr-5 gl-w-half gl-xs-w-full"
      >
        <gl-form-input
          id="first_name"
          :value="firstName"
          name="first_name"
          data-qa-selector="first_name"
          data-testid="first_name"
          required
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.lastNameLabel"
        label-size="sm"
        label-for="last_name"
        class="gl-w-half gl-xs-w-full"
      >
        <gl-form-input
          id="last_name"
          :value="lastName"
          name="last_name"
          data-qa-selector="last_name"
          data-testid="last_name"
          required
        />
      </gl-form-group>
    </div>
    <gl-form-group :label="$options.i18n.companyNameLabel" label-size="sm" label-for="company_name">
      <gl-form-input
        id="company_name"
        :value="companyName"
        name="company_name"
        data-qa-selector="company_name"
        data-testid="company_name"
        required
      />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.companySizeLabel" label-size="sm" label-for="company_size">
      <gl-form-select
        id="company_size"
        :value="companySize"
        name="company_size"
        :options="companySizeOptionsWithDefault"
        value-field="id"
        text-field="name"
        data-qa-selector="number_of_employees"
        data-testid="company_size"
        required
      />
    </gl-form-group>
    <gl-form-group
      v-if="!$apollo.loading.countries"
      :label="$options.i18n.countryLabel"
      label-size="sm"
      label-for="country"
    >
      <gl-form-select
        id="country"
        :value="country"
        name="country"
        :options="countryOptionsWithDefault"
        value-field="id"
        text-field="name"
        data-qa-selector="country"
        data-testid="country"
        required
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.phoneNumberLabel"
      label-size="sm"
      :description="$options.i18n.phoneNumberDescription"
      label-for="phone_number"
    >
      <gl-form-input
        id="phone_number"
        :value="phoneNumber"
        name="phone_number"
        type="tel"
        data-qa-selector="telephone_number"
        data-testid="phone_number"
        pattern="^(\+)*[0-9-\s]+$"
        required
      />
    </gl-form-group>
    <gl-button type="submit" variant="confirm" class="gl-w-20" data-qa-selector="continue">
      {{ $options.i18n.formSubmitText }}
    </gl-button>
  </gl-form>
</template>
