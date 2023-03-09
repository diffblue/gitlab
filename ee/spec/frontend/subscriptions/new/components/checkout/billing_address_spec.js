import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import { mockTracking } from 'helpers/tracking_helper';
import { STEPS } from 'ee/subscriptions/constants';
import BillingAddress from 'ee/subscriptions/new/components/checkout/billing_address.vue';
import { getStoreConfig } from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';

Vue.use(Vuex);
Vue.use(VueApollo);

describe('Billing Address', () => {
  let store;
  let wrapper;
  let mockApolloProvider;

  const actionMocks = {
    fetchCountries: jest.fn(),
    fetchStates: jest.fn(),
  };

  function activateNextStep() {
    return mockApolloProvider.clients.defaultClient.mutate({
      mutation: activateNextStepMutation,
    });
  }

  function createStore() {
    const { actions, ...storeConfig } = getStoreConfig();
    return new Vuex.Store({
      ...storeConfig,
      actions: { ...actions, ...actionMocks },
    });
  }

  function createComponent(options = {}) {
    return mount(BillingAddress, {
      ...options,
    });
  }

  beforeEach(() => {
    store = createStore();
    mockApolloProvider = createMockApolloProvider(STEPS);
    wrapper = createComponent({ store, apolloProvider: mockApolloProvider });
  });

  describe('mounted', () => {
    it('should load the countries', () => {
      expect(actionMocks.fetchCountries).toHaveBeenCalled();
    });
  });

  describe('country options', () => {
    const countrySelect = () => wrapper.find('.js-country');

    beforeEach(() => {
      store.commit(types.UPDATE_COUNTRY_OPTIONS, [{ text: 'Netherlands', value: 'NL' }]);
    });

    it('should display the select prompt', () => {
      expect(countrySelect().html()).toContain('<option value="">Select a country</option>');
    });

    it('should display the countries returned from the server', () => {
      expect(countrySelect().html()).toContain('<option value="NL">Netherlands</option>');
    });

    it('should fetch states when selecting a country', async () => {
      countrySelect().trigger('change');
      await nextTick();

      expect(actionMocks.fetchStates).toHaveBeenCalled();
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_COUNTRY, 'US');
      store.commit(types.UPDATE_ZIP_CODE, '10467');
      store.commit(types.UPDATE_COUNTRY_STATE, 'NY');
    });

    it('tracks completion details', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      wrapper.findComponent(Step).vm.$emit('nextStep');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'select_country',
        property: 'US',
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'state',
        property: 'NY',
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'saas_checkout_postal_code',
        property: '10467',
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'continue_payment',
      });
    });

    it('tracks step edits', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      wrapper.findComponent(Step).vm.$emit('stepEdit', 'stepID');
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'edit',
        property: 'billingAddress',
      });
    });
  });

  describe('validations', () => {
    const isStepValid = () => wrapper.findComponent(Step).props('isValid');

    beforeEach(() => {
      store.commit(types.UPDATE_COUNTRY, 'country');
      store.commit(types.UPDATE_STREET_ADDRESS_LINE_ONE, 'address line 1');
      store.commit(types.UPDATE_CITY, 'city');
      store.commit(types.UPDATE_ZIP_CODE, 'zip');
    });

    it('should be valid when country, streetAddressLine1, city and zipCode have been entered', () => {
      expect(isStepValid()).toBe(true);
    });

    it('should be invalid when country is undefined', async () => {
      store.commit(types.UPDATE_COUNTRY, null);
      await nextTick();

      expect(isStepValid()).toBe(false);
    });

    it('should be invalid when state is undefined for countries that require state', async () => {
      store.commit(types.UPDATE_COUNTRY, 'US');
      store.commit(types.UPDATE_COUNTRY_STATE, null);
      await nextTick();

      expect(isStepValid()).toBe(false);
    });

    it(`should be valid when state is undefined for countries that don't require state`, async () => {
      store.commit(types.UPDATE_COUNTRY, 'NZL');
      store.commit(types.UPDATE_COUNTRY_STATE, null);
      await nextTick();

      expect(isStepValid()).toBe(true);
    });

    it('should be invalid when streetAddressLine1 is undefined', async () => {
      store.commit(types.UPDATE_STREET_ADDRESS_LINE_ONE, null);
      await nextTick();

      expect(isStepValid()).toBe(false);
    });

    it('should be invalid when city is undefined', async () => {
      store.commit(types.UPDATE_CITY, null);
      await nextTick();

      expect(isStepValid()).toBe(false);
    });

    it('should be invalid when zipCode is undefined', async () => {
      store.commit(types.UPDATE_ZIP_CODE, null);
      await nextTick();

      expect(isStepValid()).toBe(false);
    });
  });

  describe('showing the summary', () => {
    beforeEach(async () => {
      store.commit(types.UPDATE_COUNTRY, 'country');
      store.commit(types.UPDATE_STREET_ADDRESS_LINE_ONE, 'address line 1');
      store.commit(types.UPDATE_STREET_ADDRESS_LINE_TWO, 'address line 2');
      store.commit(types.UPDATE_COUNTRY_STATE, 'state');
      store.commit(types.UPDATE_CITY, 'city');
      store.commit(types.UPDATE_ZIP_CODE, 'zip');
      await activateNextStep();
      await activateNextStep();
    });

    it('should show the entered address line 1', () => {
      expect(wrapper.find('.js-summary-line-1').text()).toEqual('address line 1');
    });

    it('should show the entered address line 2', () => {
      expect(wrapper.find('.js-summary-line-2').text()).toEqual('address line 2');
    });

    it('should show the entered address city, state and zip code', () => {
      expect(wrapper.find('.js-summary-line-3').text()).toEqual('city, state zip');
    });
  });
});
