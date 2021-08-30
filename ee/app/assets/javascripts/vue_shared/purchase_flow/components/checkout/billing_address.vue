<script>
import { GlFormGroup, GlFormInput, GlFormSelect } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { STEPS } from 'ee/subscriptions/constants';
import updateStateMutation from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import statesQuery from 'ee/subscriptions/graphql/queries/states.query.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  components: {
    Step,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
  },
  directives: {
    autofocusonshow,
  },
  data() {
    return {
      countries: [],
    };
  },
  apollo: {
    customer: {
      query: stateQuery,
    },
    countries: {
      query: countriesQuery,
    },
    states: {
      query: statesQuery,
      skip() {
        return !this.customer.country;
      },
      variables() {
        return {
          countryId: this.customer.country,
        };
      },
    },
  },
  computed: {
    countryModel: {
      get() {
        return this.customer.country;
      },
      set(country) {
        this.updateState({ customer: { country, state: null } });
      },
    },
    streetAddressLine1Model: {
      get() {
        return this.customer.address1;
      },
      set(address1) {
        this.updateState({ customer: { address1 } });
      },
    },
    streetAddressLine2Model: {
      get() {
        return this.customer.address2;
      },
      set(address2) {
        this.updateState({ customer: { address2 } });
      },
    },
    cityModel: {
      get() {
        return this.customer.city;
      },
      set(city) {
        this.updateState({ customer: { city } });
      },
    },
    countryStateModel: {
      get() {
        return this.customer.state;
      },
      set(state) {
        this.updateState({ customer: { state } });
      },
    },
    zipCodeModel: {
      get() {
        return this.customer.zipCode;
      },
      set(zipCode) {
        this.updateState({ customer: { zipCode } });
      },
    },
    isValid() {
      return (
        !isEmpty(this.customer.country) &&
        !isEmpty(this.customer.address1) &&
        !isEmpty(this.customer.city) &&
        !isEmpty(this.customer.zipCode)
      );
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
    stateOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.stateSelectPrompt,
          id: null,
        },
        ...this.states,
      ];
    },
    selectedStateName() {
      if (!this.customer.state || !this.states) {
        return '';
      }

      return this.states.find((state) => state.id === this.customer.state).name;
    },
  },
  methods: {
    updateState(payload) {
      this.$apollo
        .mutate({
          mutation: updateStateMutation,
          variables: {
            input: payload,
          },
        })
        .catch((error) => {
          createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
        });
    },
  },
  i18n: {
    stepTitle: s__('Checkout|Billing address'),
    nextStepButtonText: s__('Checkout|Continue to payment'),
    countryLabel: s__('Checkout|Country'),
    countrySelectPrompt: s__('Checkout|Please select a country'),
    streetAddressLabel: s__('Checkout|Street address'),
    cityLabel: s__('Checkout|City'),
    stateLabel: s__('Checkout|State'),
    stateSelectPrompt: s__('Checkout|Please select a state'),
    zipCodeLabel: s__('Checkout|Zip code'),
  },
  stepId: STEPS[1].id,
};
</script>
<template>
  <step
    v-if="!$apollo.loading.customer"
    :step-id="$options.stepId"
    :title="$options.i18n.stepTitle"
    :is-valid="isValid"
    :next-step-button-text="$options.i18n.nextStepButtonText"
  >
    <template #body>
      <gl-form-group
        v-if="!$apollo.loading.countries"
        :label="$options.i18n.countryLabel"
        label-size="sm"
        class="mb-3"
      >
        <gl-form-select
          v-model="countryModel"
          v-autofocusonshow
          :options="countryOptionsWithDefault"
          class="js-country"
          value-field="id"
          text-field="name"
          data-qa-selector="country"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.streetAddressLabel" label-size="sm" class="mb-3">
        <gl-form-input
          v-model="streetAddressLine1Model"
          type="text"
          data-qa-selector="street_address_1"
        />
        <gl-form-input
          v-model="streetAddressLine2Model"
          type="text"
          data-qa-selector="street_address_2"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.cityLabel" label-size="sm" class="mb-3">
        <gl-form-input v-model="cityModel" type="text" data-qa-selector="city" />
      </gl-form-group>
      <div class="combined d-flex">
        <gl-form-group
          v-if="!$apollo.loading.states && states"
          :label="$options.i18n.stateLabel"
          label-size="sm"
          class="mr-3 w-50"
        >
          <gl-form-select
            v-model="countryStateModel"
            :options="stateOptionsWithDefault"
            value-field="id"
            text-field="name"
            data-qa-selector="state"
          />
        </gl-form-group>
        <gl-form-group :label="$options.i18n.zipCodeLabel" label-size="sm" class="w-50">
          <gl-form-input v-model="zipCodeModel" type="text" data-qa-selector="zip_code" />
        </gl-form-group>
      </div>
    </template>
    <template #summary>
      <div class="js-summary-line-1">{{ customer.address1 }}</div>
      <div class="js-summary-line-2">{{ customer.address2 }}</div>
      <div class="js-summary-line-3">
        {{ customer.city }}, {{ customer.country }} {{ selectedStateName }} {{ customer.zipCode }}
      </div>
    </template>
  </step>
</template>
