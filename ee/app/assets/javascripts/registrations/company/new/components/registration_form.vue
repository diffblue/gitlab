<script>
import { GlForm, GlButton, GlFormGroup, GlFormInput, GlFormSelect, GlFormText } from '@gitlab/ui';
import {
  LEADS_COMPANY_NAME_LABEL,
  LEADS_COMPANY_SIZE_LABEL,
  companySizes,
} from 'ee/vue_shared/leads/constants';
import csrf from '~/lib/utils/csrf';
import CountryOrRegionSelector from '../../../../trials/components/country_or_region_selector.vue';
import {
  TRIAL_COMPANY_SIZE_PROMPT,
  TRIAL_PHONE_DESCRIPTION,
  TRIAL_FORM_SUBMIT_TEXT,
} from '../../../../trials/constants';
import RegistrationTrialToggle from '../../../components/registration_trial_toggle.vue';

export default {
  csrf,
  components: {
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormText,
    CountryOrRegionSelector,
    RegistrationTrialToggle,
  },
  inject: ['createLeadPath'],
  props: {
    trial: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      companyName: '',
      companySize: null,
      phoneNumber: null,
      country: '',
      state: '',
      website: '',
    };
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
  },
  i18n: {
    companyNameLabel: LEADS_COMPANY_NAME_LABEL,
    companySizeLabel: LEADS_COMPANY_SIZE_LABEL,
    companySizeSelectPrompt: TRIAL_COMPANY_SIZE_PROMPT,
    formSubmitText: TRIAL_FORM_SUBMIT_TEXT,
    phoneNumberDescription: TRIAL_PHONE_DESCRIPTION,
  },
};
</script>

<template>
  <gl-form :action="createLeadPath" method="post" novalidate>
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-mt-5">
      <gl-form-group
        :label="$options.i18n.companyNameLabel"
        label-size="sm"
        label-for="company_name"
        class="gl-mr-5 gl-w-half gl-xs-w-full"
      >
        <gl-form-input
          id="company_name"
          :value="companyName"
          name="company_name"
          data-testid="company_name"
          required
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.companySizeLabel"
        label-size="sm"
        label-for="company_size"
        class="gl-w-half gl-xs-w-full company-size"
      >
        <gl-form-select
          id="company_size"
          :value="companySize"
          name="company_size"
          :options="companySizeOptionsWithDefault"
          value-field="id"
          text-field="name"
          data-testid="company_size"
          required
        />
      </gl-form-group>
    </div>
    <country-or-region-selector :country="country" :state="state" data-testid="country" required />
    <gl-form-group
      label="Telephone Number (Optional)"
      label-size="sm"
      :description="$options.i18n.phoneNumberDescription"
      label-for="phone_number"
    >
      <gl-form-input
        id="phone_number"
        :value="phoneNumber"
        name="phone_number"
        type="tel"
        data-testid="phone_number"
        pattern="^(\+)*[0-9-\s]+$"
      />
    </gl-form-group>
    <gl-form-group label="Website (Optional)" label-size="sm" label-for="website">
      <gl-form-input id="website" :value="website" name="website" data-testid="website" />
    </gl-form-group>
    <gl-form-group label="GitLab Ultimate trial (optional)" label-size="sm">
      <gl-form-text class="gl-pb-3">{{
        __('Try all GitLab features for free for 30 days. No credit card required.')
      }}</gl-form-text>
      <registration-trial-toggle :active="trial" data-testid="trial" />
    </gl-form-group>
    <gl-button type="submit" variant="confirm" class="gl-w-20">
      {{ $options.i18n.formSubmitText }}
    </gl-button>
  </gl-form>
</template>

<style>
.company-size .bv-no-focus-ring {
  margin-top: -3px;
}
</style>
