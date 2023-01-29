import Vue from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import * as Sentry from '@sentry/browser';
import { triggerEvent, mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Component from 'ee/subscriptions/new/components/order_summary.vue';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PromoCodeInput from 'ee/subscriptions/new/components/promo_code_input.vue';
import { createMockClient } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import invoicePreviewQuery from 'ee/subscriptions/graphql/queries/new_subscription_invoice_preview.customer.query.graphql';
import { VALIDATION_ERROR_CODE } from 'ee/subscriptions/new/constants';
import {
  mockInvoicePreviewBronze,
  mockInvoicePreviewUltimate,
  mockInvoicePreviewUltimateWithMultipleUsers,
} from 'ee_jest/subscriptions/mock_data';

describe('Order Summary', () => {
  Vue.use(Vuex);
  Vue.use(VueApollo);

  let wrapper;
  let trackingSpy;

  const availablePlans = [
    { id: 'firstPlanId', code: 'bronze', price_per_year: 48, name: 'bronze plan' },
    {
      id: 'secondPlanId',
      code: 'silver',
      price_per_year: 228,
      name: 'silver plan',
      eligible_to_use_promo_code: true,
    },
    {
      id: 'thirdPlanId',
      code: 'gold',
      price_per_year: 1188,
      name: 'gold plan',
      eligible_to_use_promo_code: false,
    },
  ];

  const initialData = {
    availablePlans: JSON.stringify(availablePlans),
    planId: 'thirdPlanId',
    namespaceId: null,
    fullName: 'Full Name',
  };

  const findTaxHelpLink = () => wrapper.findByTestId('tax-help-link');
  const findPromoCodeInput = () => wrapper.findComponent(PromoCodeInput);

  const taxInfoLine = () => wrapper.findByTestId('tax-info-line').text();
  const totalOriginalPrice = () => wrapper.findByTestId('amount').text();
  const totalOriginalPriceExcludingVat = () => wrapper.findByTestId('total-ex-vat').text();
  const totalPriceToBeCharged = () => wrapper.findByTestId('total-amount').text();
  const vat = () => wrapper.findByTestId('vat').text();
  const perUserPriceInfo = () => wrapper.findByTestId('per-user').text();
  const numberOfUsers = () => wrapper.findByTestId('number-of-users').text();
  const selectedPlan = () => wrapper.findByTestId('selected-plan').text();
  const subscriptionTerm = () => wrapper.findByTestId('dates').text();

  const assertEmptyPriceDetails = () => {
    expect(totalOriginalPrice()).toBe('-');
    expect(totalOriginalPriceExcludingVat()).toBe('-');
    expect(totalPriceToBeCharged()).toBe('-');
  };

  const store = createStore(initialData);

  const invoicePreviewQuerySpy = jest.fn().mockResolvedValue(mockInvoicePreviewUltimate);

  const createComponent = async (invoicePreviewSpy = invoicePreviewQuerySpy) => {
    const mockCustomersDotClient = createMockClient([[invoicePreviewQuery, invoicePreviewSpy]]);
    const mockApollo = new VueApollo({
      defaultClient: mockCustomersDotClient,
      clients: {
        [CUSTOMERSDOT_CLIENT]: mockCustomersDotClient,
      },
    });
    wrapper = mountExtended(Component, {
      apolloProvider: mockApollo,
      store,
    });
    await waitForPromises();
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
    wrapper.destroy();
    invoicePreviewQuerySpy.mockClear();
  });

  describe('Changing the company name', () => {
    beforeEach(() => {
      return createComponent();
    });

    describe('When purchasing for a single user', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, false);
      });

      it('displays the title with the passed name', () => {
        expect(wrapper.find('h4').text()).toContain("Full Name's GitLab subscription");
      });
    });

    describe('When purchasing for a company or group', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
      });

      describe('Without a group name provided', () => {
        it('displays the title with the default name', () => {
          expect(wrapper.find('h4').text()).toContain("Your organization's GitLab subscription");
        });
      });

      describe('With a group name provided', () => {
        beforeEach(() => {
          store.commit(types.UPDATE_ORGANIZATION_NAME, 'My group');
        });

        it('displays the title with the group name', () => {
          expect(wrapper.find('h4').text()).toContain("My group's GitLab subscription");
        });
      });
    });
  });

  describe('changing the plan', () => {
    describe('with default initial selected plan', () => {
      beforeEach(() => {
        return createComponent();
      });

      it('displays the chosen plan', () => {
        expect(selectedPlan()).toContain('Gold plan');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(perUserPriceInfo()).toBe('$1,188 per user per year');
      });

      it('calls invoice preview API with appropriate params', () => {
        expect(invoicePreviewQuerySpy).toHaveBeenCalledWith({
          planId: 'thirdPlanId',
          quantity: 1,
        });
      });
    });

    describe('with the selected plan', () => {
      const invoicePreviewSpy = jest.fn().mockResolvedValue(mockInvoicePreviewBronze);

      beforeEach(async () => {
        await createComponent(invoicePreviewSpy);

        store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
        await waitForPromises();
      });

      it('displays the chosen plan', () => {
        expect(selectedPlan()).toContain('Bronze plan');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(perUserPriceInfo()).toBe('$48 per user per year');
      });

      it('displays the correct formatted total amount', () => {
        expect(totalPriceToBeCharged()).toBe('$48');
      });

      it('calls invoice preview API with appropriate params', () => {
        expect(invoicePreviewSpy).toHaveBeenCalledWith({
          planId: 'firstPlanId',
          quantity: 1,
        });
      });

      afterAll(() => {
        store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');
      });
    });
  });

  describe('Changing the number of users', () => {
    describe('with the default of 1 selected user', () => {
      beforeEach(() => {
        return createComponent();
      });
      it('displays the correct number of users', () => {
        expect(numberOfUsers()).toBe('(x1)');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(perUserPriceInfo()).toBe('$1,188 per user per year');
      });

      it('displays the correct formatted total amount', () => {
        expect(totalPriceToBeCharged()).toBe('$1,188');
      });

      it('calls invoice preview API with appropriate params', () => {
        expect(invoicePreviewQuerySpy).toHaveBeenCalledWith({
          planId: 'thirdPlanId',
          quantity: 1,
        });
      });
    });

    describe('with 3 selected users', () => {
      const invoicePreviewSpy = jest
        .fn()
        .mockResolvedValue(mockInvoicePreviewUltimateWithMultipleUsers);

      beforeEach(async () => {
        await createComponent(invoicePreviewSpy);
        store.commit(types.UPDATE_NUMBER_OF_USERS, 3);
        await waitForPromises();
      });

      it('displays the correct number of users', () => {
        expect(numberOfUsers()).toBe('(x3)');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(perUserPriceInfo()).toBe('$1,188 per user per year');
      });

      it('displays the correct multiplied formatted amount of the chosen plan', () => {
        expect(totalOriginalPrice()).toBe('$3,564');
      });

      it('displays the correct formatted total amount', () => {
        expect(totalPriceToBeCharged()).toBe('$3,564');
      });

      it('calls invoice preview API with appropriate params', () => {
        expect(invoicePreviewSpy).toHaveBeenCalledWith({
          planId: 'thirdPlanId',
          quantity: 3,
        });
      });

      afterAll(() => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 1);
      });
    });

    describe('with no selected users', () => {
      beforeEach(async () => {
        await createComponent();
        store.commit(types.UPDATE_NUMBER_OF_USERS, 0);
        await waitForPromises();
      });

      it('should not display the number of users', () => {
        expect(wrapper.findByTestId('number-of-users').exists()).toBe(false);
      });

      it('displays the correct formatted amount price per user', () => {
        expect(perUserPriceInfo()).toBe('$1,188 per user per year');
      });

      it('does not show price details', () => {
        assertEmptyPriceDetails();
      });

      afterAll(() => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 1);
      });
    });

    describe('date range', () => {
      beforeEach(() => {
        return createComponent();
      });

      it('shows the formatted date range from the start date to one year in the future', () => {
        expect(subscriptionTerm()).toBe('Dec 5, 2019 - Dec 5, 2020');
      });
    });

    describe('tax rate', () => {
      beforeEach(() => {
        return createComponent();
      });

      describe('tracking', () => {
        it('track click on tax_link', () => {
          trackingSpy = mockTracking(undefined, findTaxHelpLink().element, jest.spyOn);
          triggerEvent(findTaxHelpLink().element);

          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'tax_link',
          });
        });
      });

      describe('with a tax rate of 0', () => {
        it('displays the total amount excluding vat', () => {
          expect(wrapper.findByTestId('total-ex-vat').exists()).toBe(true);
        });

        it('displays the vat amount with a stopgap', () => {
          expect(vat()).toBe('–');
        });

        it('displays an info line', () => {
          expect(taxInfoLine()).toMatchInterpolatedText('Tax (may be charged upon purchase)');
        });

        it('contains a help link', () => {
          expect(findTaxHelpLink().attributes('href')).toBe(
            'https://about.gitlab.com/handbook/tax/#indirect-taxes-management',
          );
        });
      });

      describe('a tax rate of 8%', () => {
        beforeEach(() => {
          store.state.taxRate = 0.08;
        });

        it('displays the total amount excluding vat', () => {
          expect(totalOriginalPriceExcludingVat()).toBe('$1,188');
        });

        it('displays the vat amount', () => {
          expect(vat()).toBe('$95.04');
        });

        it('displays the total amount including the vat', () => {
          expect(totalPriceToBeCharged()).toBe('$1,283.04');
        });

        it('displays an info line', () => {
          expect(taxInfoLine()).toMatchInterpolatedText('Tax (may be charged upon purchase)');
        });

        it('contains a help link', () => {
          expect(findTaxHelpLink().attributes('href')).toBe(
            'https://about.gitlab.com/handbook/tax/#indirect-taxes-management',
          );
        });
      });
    });
  });

  describe('Error handling', () => {
    const errorMessage = 'I failed!';

    describe('when API has errors in the response', () => {
      it('emits an event with received error message', async () => {
        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ extensions: { message: errorMessage } }] });
        await createComponent(invoicePreviewSpy);

        expect(wrapper.emitted('error')[0]).toEqual([errorMessage]);
      });

      it('does not show price details', async () => {
        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ extensions: { message: errorMessage } }] });
        await createComponent(invoicePreviewSpy);

        assertEmptyPriceDetails();
      });

      it('does not capture exception on Sentry for validation errors', async () => {
        const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');

        const invoicePreviewSpy = jest.fn().mockResolvedValue({
          data: {},
          errors: [{ extensions: { message: errorMessage, code: VALIDATION_ERROR_CODE } }],
        });
        await createComponent(invoicePreviewSpy);

        expect(sentryCaptureExceptionSpy).not.toHaveBeenCalled();
      });

      it('captures exception on Sentry for non-validation errors', async () => {
        const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');

        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ extensions: { message: errorMessage } }] });
        await createComponent(invoicePreviewSpy);

        expect(sentryCaptureExceptionSpy).toHaveBeenCalled();
      });
    });

    describe('when API has errors in unrecognisable format', () => {
      beforeEach(() => {
        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ somethingElse: 'Error' }] });
        return createComponent(invoicePreviewSpy);
      });

      it('emits an event to send error', () => {
        expect(wrapper.emitted('error')[0]).toEqual([
          'Something went wrong while loading price details.',
        ]);
      });

      it('does not show price details', () => {
        assertEmptyPriceDetails();
      });
    });

    describe('when there are network errors', () => {
      beforeEach(() => {
        const invoicePreviewSpy = jest.fn().mockRejectedValue(new Error('Error'));
        return createComponent(invoicePreviewSpy);
      });

      it('emits an event to send error', () => {
        expect(wrapper.emitted('error')[0]).toEqual(['Network Error: Error']);
      });

      it('does not show price details', () => {
        assertEmptyPriceDetails();
      });
    });
  });

  describe('promo code', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('shows promo code input if eligible', async () => {
      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');

      expect(findPromoCodeInput().exists()).toBe(true);
    });

    it('doesnt show promo code input if not eligible', async () => {
      await store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');

      expect(findPromoCodeInput().exists()).toBe(false);

      await store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');

      expect(findPromoCodeInput().exists()).toBe(false);
    });
  });
});
