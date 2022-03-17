<script>
import { GlFormGroup, GlFormSelect } from '@gitlab/ui';
import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import statesQuery from 'ee/subscriptions/graphql/queries/states.query.graphql';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import {
  COUNTRIES_WITH_STATES_ALLOWED,
  LEADS_COUNTRY_LABEL,
  LEADS_COUNTRY_PROMPT,
} from 'ee/vue_shared/leads/constants';
import { TRIAL_STATE_LABEL, TRIAL_STATE_PROMPT } from '../constants';

export default {
  name: 'CountryOrRegionSelector',
  components: {
    GlFormGroup,
    GlFormSelect,
  },
  directives: {
    autofocusonshow,
  },
  props: {
    country: {
      type: String,
      required: true,
    },
    state: {
      type: String,
      required: true,
    },
    required: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return { selectedCountry: this.country, selectedState: this.state, countries: [], states: [] };
  },
  i18n: {
    countryLabel: LEADS_COUNTRY_LABEL,
    countrySelectPrompt: LEADS_COUNTRY_PROMPT,
    stateLabel: TRIAL_STATE_LABEL,
    stateSelectPrompt: TRIAL_STATE_PROMPT,
  },
  computed: {
    countryOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.countrySelectPrompt,
          id: '',
        },
        ...this.countries,
      ];
    },
    stateRequired() {
      return COUNTRIES_WITH_STATES_ALLOWED.includes(this.selectedCountry);
    },
    showState() {
      return (
        !this.$apollo.loading.states && this.states && this.selectedCountry && this.stateRequired
      );
    },
    stateOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.stateSelectPrompt,
          id: '',
        },
        ...this.states,
      ];
    },
  },
  methods: {
    selected() {
      this.setSelectedState();

      this.$emit('change', {
        country: this.selectedCountry,
        state: this.selectedState,
        stateRequired: this.stateRequired,
      });
    },
    setSelectedState() {
      if (!this.showState) {
        this.selectedState = '';
      }
    },
  },
  apollo: {
    countries: {
      query: countriesQuery,
    },
    states: {
      query: statesQuery,
      skip() {
        return !this.selectedCountry;
      },
      variables() {
        return {
          countryId: this.selectedCountry,
        };
      },
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      v-if="!$apollo.loading.countries"
      :label="$options.i18n.countryLabel"
      label-size="sm"
      label-for="country"
    >
      <gl-form-select
        id="country"
        v-model="selectedCountry"
        name="country"
        :options="countryOptionsWithDefault"
        value-field="id"
        text-field="name"
        data-qa-selector="country"
        data-testid="country"
        :required="required"
        @change="selected"
      />
    </gl-form-group>
    <gl-form-group
      v-if="showState"
      :label="$options.i18n.stateLabel"
      label-size="sm"
      label-for="state"
    >
      <gl-form-select
        id="state"
        v-model="selectedState"
        v-autofocusonshow
        name="state"
        :options="stateOptionsWithDefault"
        value-field="id"
        text-field="name"
        data-qa-selector="state"
        data-testid="state"
        :required="required"
        @change="selected"
      />
    </gl-form-group>
  </div>
</template>
