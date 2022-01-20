<script>
import { GlFormGroup, GlFormSelect } from '@gitlab/ui';
import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import { LEADS_COUNTRY_LABEL, LEADS_COUNTRY_PROMPT } from 'ee/vue_shared/leads/constants';

export default {
  name: 'CountryOrRegionList',
  components: {
    GlFormGroup,
    GlFormSelect,
  },
  inject: ['user'],
  data() {
    return { ...this.user, countries: [] };
  },
  i18n: {
    countryLabel: LEADS_COUNTRY_LABEL,
    countrySelectPrompt: LEADS_COUNTRY_PROMPT,
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
  },
  apollo: {
    countries: {
      query: countriesQuery,
    },
  },
};
</script>

<template>
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
</template>
