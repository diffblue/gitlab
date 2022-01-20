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
  inject: ['user'],
  data() {
    return { ...this.user, countries: [], states: [] };
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
          id: null,
        },
        ...this.countries,
      ];
    },
    mustEnterState() {
      return COUNTRIES_WITH_STATES_ALLOWED.includes(this.country);
    },
    showState() {
      return !this.$apollo.loading.states && this.states && this.country && this.mustEnterState;
    },
    stateOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.stateSelectPrompt,
          id: null,
        },
        ...this.states,
      ];
    },
  },
  apollo: {
    countries: {
      query: countriesQuery,
    },
    states: {
      query: statesQuery,
      skip() {
        return !this.country;
      },
      variables() {
        return {
          countryId: this.country,
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
        v-model="country"
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
      v-if="showState"
      :label="$options.i18n.stateLabel"
      label-size="sm"
      label-for="state"
    >
      <gl-form-select
        id="state"
        v-autofocusonshow
        :value="state"
        name="state"
        :options="stateOptionsWithDefault"
        value-field="id"
        text-field="name"
        data-testid="state"
        required
      />
    </gl-form-group>
  </div>
</template>
