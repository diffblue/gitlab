import Vue from 'vue';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import * as Sentry from '@sentry/browser';
import { gitLabResolvers } from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import BillingAddress from 'ee/vue_shared/purchase_flow/components/checkout/billing_address.vue';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { stateData as initialStateData } from 'ee_jest/subscriptions/mock_data';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(VueApollo);

describe('Billing Address', () => {
  let wrapper;
  let updateState = jest.fn();

  const findCountrySelect = () => wrapper.findByTestId('country-select');

  const createComponent = (apolloLocalState = {}) => {
    const apolloResolvers = {
      Query: {
        countries: jest.fn().mockResolvedValue([
          { id: 'NL', name: 'Netherlands', flag: 'NL', internationalDialCode: '31' },
          { id: 'US', name: 'United States of America', flag: 'US', internationalDialCode: '1' },
        ]),
        states: jest.fn().mockResolvedValue([{ id: 'CA', name: 'California' }]),
      },
      Mutation: { updateState },
    };

    const apolloProvider = createMockApolloProvider(STEPS, STEPS[1], {
      ...gitLabResolvers,
      ...apolloResolvers,
    });
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data: merge({}, initialStateData, apolloLocalState),
    });

    wrapper = mountExtended(BillingAddress, {
      apolloProvider,
    });
  };

  describe('country options', () => {
    const countrySelect = () => wrapper.find('.js-country');

    beforeEach(() => {
      createComponent();

      return waitForPromises();
    });

    it('displays the countries returned from the server', () => {
      expect(countrySelect().html()).toContain('<option value="NL">Netherlands</option>');
    });
  });

  describe('validations', () => {
    const isStepValid = () => wrapper.findComponent(Step).props('isValid');
    const customerData = {
      country: 'US',
      address1: 'address line 1',
      address2: 'address line 2',
      city: 'city',
      zipCode: 'zip',
      state: null,
    };

    it('is valid when country, streetAddressLine1, city and zipCode have been entered', async () => {
      createComponent({ customer: customerData });

      await waitForPromises();

      expect(isStepValid()).toBe(true);
    });

    it('is invalid when country is undefined', async () => {
      createComponent({ customer: { country: null } });

      await waitForPromises();

      expect(isStepValid()).toBe(false);
    });

    it('is invalid when streetAddressLine1 is undefined', async () => {
      createComponent({ customer: { address1: null } });

      await waitForPromises();

      expect(isStepValid()).toBe(false);
    });

    it('is invalid when city is undefined', async () => {
      createComponent({ customer: { city: null } });

      await waitForPromises();

      expect(isStepValid()).toBe(false);
    });

    it('is invalid when zipCode is undefined', async () => {
      createComponent({ customer: { zipCode: null } });

      await waitForPromises();

      expect(isStepValid()).toBe(false);
    });
  });

  describe('showing the summary', () => {
    beforeEach(() => {
      createComponent({
        customer: {
          country: 'US',
          address1: 'address line 1',
          address2: 'address line 2',
          city: 'city',
          zipCode: 'zip',
          state: 'CA',
        },
      });

      return waitForPromises();
    });

    it('should show the entered address line 1', () => {
      expect(wrapper.find('.js-summary-line-1').text()).toBe('address line 1');
    });

    it('should show the entered address line 2', () => {
      expect(wrapper.find('.js-summary-line-2').text()).toBe('address line 2');
    });

    it('should show the entered address city, state and zip code', () => {
      expect(wrapper.find('.js-summary-line-3').text()).toBe('city, US California zip');
    });
  });

  describe('when an error occurs with the resolver', () => {
    const error = new Error('Yikes!');

    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      updateState = jest.fn().mockRejectedValue(error);
      createComponent({
        customer: { country: 'US' },
      });

      findCountrySelect().vm.$emit('input', 'IT');

      return waitForPromises();
    });

    it('emits an error', () => {
      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    it('captures the exception', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });
});
