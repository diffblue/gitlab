import Vue from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
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
import {
  VALIDATION_ERROR_CODE,
  PROMO_CODE_ERROR_ATTRIBUTE,
  INVALID_PROMO_CODE_ERROR_CODE,
  PROMO_CODE_USER_QUANTITY_ERROR_MESSAGE,
  INVALID_PROMO_CODE_ERROR_MESSAGE,
  PurchaseEvent,
} from 'ee/subscriptions/new/constants';
import {
  mockDiscountItem,
  mockInvoicePreviewBronze,
  mockInvoicePreviewUltimate,
  mockInvoicePreviewUltimateWithMultipleUsers,
  mockNamespaces,
  mockInvoicePreviewWithDiscount,
} from 'ee_jest/subscriptions/mock_data';

jest.mock('~/alert');

describe('Order Summary', () => {
  Vue.use(Vuex);
  Vue.use(VueApollo);

  let wrapper;
  let trackingSpy;

  const promotionalOfferText = 'Promotional Offer Text';

  const availablePlans = [
    { id: 'firstPlanId', code: 'bronze', price_per_year: 48, name: 'bronze plan' },
    {
      id: 'secondPlanId',
      code: 'silver',
      price_per_year: 228,
      name: 'silver plan',
      eligible_to_use_promo_code: true,
      promotional_offer_text: promotionalOfferText,
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
    groupData: mockNamespaces,
  };

  const invalidPromoCodeResponse = {
    data: {},
    errors: [
      {
        extensions: {
          message: 'Error',
          code: INVALID_PROMO_CODE_ERROR_CODE,
          attributes: [PROMO_CODE_ERROR_ATTRIBUTE],
        },
      },
    ],
  };

  const findTaxHelpLink = () => wrapper.findByTestId('tax-help-link');
  const findPromoCodeInput = () => wrapper.findComponent(PromoCodeInput);
  const findPromotionalOfferText = () => wrapper.findByTestId('promotional-offer-text');

  const discount = () => wrapper.findByTestId('discount').text();
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

  let store;

  const initialiseStore = () => {
    store = createStore(initialData);
  };

  const invoicePreviewQuerySpy = jest.fn().mockResolvedValue(mockInvoicePreviewUltimate);

  const createComponent = (
    invoicePreviewSpy = invoicePreviewQuerySpy,
    useInvoicePreviewApiInSaasPurchase = true,
  ) => {
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
      provide: {
        glFeatures: { useInvoicePreviewApiInSaasPurchase },
      },
    });
    return waitForPromises();
  };

  beforeEach(() => {
    initialiseStore();
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
    gon.features = { useInvoicePreviewApiInSaasPurchase: true };
  });

  afterEach(() => {
    unmockTracking();
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
          namespaceId: null,
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
          namespaceId: null,
          planId: 'firstPlanId',
          quantity: 1,
        });
      });

      it('emits `error-reset` event', () => {
        expect(wrapper.emitted(PurchaseEvent.ERROR_RESET)).toHaveLength(2);
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
          namespaceId: null,
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
          namespaceId: null,
          planId: 'thirdPlanId',
          quantity: 3,
        });
      });
    });

    describe('with selected group', () => {
      const invoicePreviewSpy = jest.fn().mockResolvedValue(mockInvoicePreviewUltimate);

      beforeEach(async () => {
        await createComponent(invoicePreviewSpy);
        await store.commit(types.UPDATE_SELECTED_GROUP, 132);
        await waitForPromises();
      });

      it('displays the correct formatted amount price per user', () => {
        expect(perUserPriceInfo()).toBe('$1,188 per user per year');
      });

      it('displays the correct multiplied formatted amount of the chosen plan', () => {
        expect(totalOriginalPrice()).toBe('$1,188');
      });

      it('displays the correct formatted total amount', () => {
        expect(totalPriceToBeCharged()).toBe('$1,188');
      });

      it('calls invoice preview API with appropriate params', () => {
        expect(invoicePreviewSpy).toHaveBeenCalledWith({
          namespaceId: 132,
          planId: 'thirdPlanId',
          quantity: 1,
        });
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
    });

    describe('date range', () => {
      beforeEach(() => {
        return createComponent();
      });

      it('shows the formatted date range from the start date to one year in the future', () => {
        expect(subscriptionTerm()).toBe('Jul 6, 2020 - Jul 6, 2021');
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
      it('emits an error with received error message', async () => {
        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ extensions: { message: errorMessage } }] });
        await createComponent(invoicePreviewSpy);

        expect(wrapper.emitted(PurchaseEvent.ERROR)).toStrictEqual([
          [new Error(errorMessage)],
          [new Error(errorMessage)],
        ]);
      });

      it('does not show price details', async () => {
        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ extensions: { message: errorMessage } }] });
        await createComponent(invoicePreviewSpy);

        assertEmptyPriceDetails();
      });

      it('does not capture exception on Sentry for validation errors', async () => {
        const invoicePreviewSpy = jest.fn().mockResolvedValue({
          data: {},
          errors: [{ extensions: { message: errorMessage, code: VALIDATION_ERROR_CODE } }],
        });
        await createComponent(invoicePreviewSpy);

        expect(wrapper.emitted(PurchaseEvent.ERROR)).toStrictEqual([
          [new Error(errorMessage)],
          [new Error(errorMessage)],
        ]);
      });

      it('captures exception on Sentry for non-validation errors', async () => {
        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ extensions: { message: errorMessage } }] });
        await createComponent(invoicePreviewSpy);

        expect(wrapper.emitted(PurchaseEvent.ERROR)).toStrictEqual([
          [new Error(errorMessage)],
          [new Error(errorMessage)],
        ]);
      });
    });

    describe('when API has errors in unrecognisable format', () => {
      beforeEach(() => {
        const invoicePreviewSpy = jest
          .fn()
          .mockResolvedValue({ data: {}, errors: [{ somethingElse: 'Error' }] });
        return createComponent(invoicePreviewSpy);
      });

      it('emits an error', () => {
        expect(wrapper.emitted(PurchaseEvent.ERROR)).toStrictEqual([
          [new Error('Something went wrong while loading price details.')],
          [new Error('Something went wrong while loading price details.')],
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

      it('emits an error', () => {
        expect(wrapper.emitted(PurchaseEvent.ERROR)).toStrictEqual([
          [new Error('Network Error: Error')],
        ]);
      });

      it('does not show price details', () => {
        assertEmptyPriceDetails();
      });
    });
  });

  describe('promo code', () => {
    it('shows promo code input if eligible', async () => {
      await createComponent();
      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');

      expect(findPromoCodeInput().exists()).toBe(true);
    });

    it('doesnt show promo code input when useInvoicePreviewApiInSaasPurchase ff is off even when eligible', async () => {
      await createComponent(null, false);
      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');

      expect(findPromoCodeInput().exists()).toBe(false);
    });

    it('doesnt show promo code input if not eligible', async () => {
      await createComponent();
      await store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
      const promoCodeInput = findPromoCodeInput();

      expect(promoCodeInput.exists()).toBe(false);

      await store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');

      expect(promoCodeInput.exists()).toBe(false);
    });

    describe('when promo code is valid', () => {
      const invoicePreviewSpy = jest.fn().mockResolvedValue(mockInvoicePreviewWithDiscount);
      let promoCodeInput;

      beforeEach(async () => {
        await createComponent(invoicePreviewSpy);
        await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
        await store.commit(types.UPDATE_NUMBER_OF_USERS, 3);
        promoCodeInput = findPromoCodeInput();

        promoCodeInput.vm.$emit('apply-promo-code', 'promoCode');

        await waitForPromises();
      });

      it('shows success message for promo code', () => {
        expect(promoCodeInput.props()).toMatchObject({
          errorMessage: '',
          showSuccessAlert: true,
        });
      });

      it('shows discount details', () => {
        expect(discount()).toBe(`$${mockDiscountItem.chargeAmount}`);
      });

      it('calls invoice preview API with appropriate params', () => {
        expect(invoicePreviewSpy).toHaveBeenCalledWith({
          namespaceId: null,
          planId: 'secondPlanId',
          quantity: 3,
          promoCode: 'promoCode',
        });
      });

      it('tracks events for successfully applying a promo code', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
          label: 'apply_coupon_code_saas',
        });
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'success_response', {
          label: 'apply_coupon_code_success_saas',
        });
        expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'failure_response', {
          label: 'apply_coupon_code_failure_saas',
        });
      });
    });

    describe('when promo code is valid but price is not shown', () => {
      it('does not show success message for promo code', async () => {
        const invoicePreviewSpy = jest.fn().mockResolvedValue(mockInvoicePreviewWithDiscount);
        await createComponent(invoicePreviewSpy);
        await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
        await store.commit(types.UPDATE_NUMBER_OF_USERS, 3);
        const promoCodeInput = findPromoCodeInput();
        promoCodeInput.vm.$emit('apply-promo-code', 'promoCode');

        await store.commit(types.UPDATE_NUMBER_OF_USERS, 0);

        expect(promoCodeInput.props()).toMatchObject({
          errorMessage: '',
          showSuccessAlert: false,
        });
      });
    });

    describe('when promo code is invalid', () => {
      let promoCodeInput;
      let invoicePreviewSpy;
      beforeEach(async () => {
        invoicePreviewSpy = jest.fn().mockResolvedValue(invalidPromoCodeResponse);
        await createComponent(invoicePreviewSpy);
        await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
        promoCodeInput = findPromoCodeInput();

        promoCodeInput.vm.$emit('apply-promo-code', 'promoCode');

        await waitForPromises();
      });

      it('shows error message for promo code', () => {
        expect(promoCodeInput.props('errorMessage')).toBe(INVALID_PROMO_CODE_ERROR_MESSAGE);
      });

      it('does not show price details', () => {
        assertEmptyPriceDetails();
      });

      it('requests invoice preview without promo code after an invalid promo code', () => {
        expect(invoicePreviewSpy).toHaveBeenLastCalledWith({
          planId: 'secondPlanId',
          quantity: 1,
          namespaceId: null,
        });
      });

      it('when plan is changed, invoice preview spy is not called with promo code', async () => {
        // switching from firstPlan to secondPlan to make sure we are on a plan that is eligible to use a promo code
        await store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
        await waitForPromises();
        invoicePreviewSpy.mockClear();

        await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
        await waitForPromises();

        expect(invoicePreviewSpy).toHaveBeenCalledWith({
          planId: 'secondPlanId',
          quantity: 1,
          namespaceId: null,
        });
        expect(invoicePreviewSpy).toHaveBeenCalledTimes(1);
      });

      it('tracks events for failing to apply a promo code', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
          label: 'apply_coupon_code_saas',
        });
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'failure_response', {
          label: 'apply_coupon_code_failure_saas',
        });
        expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'success_response', {
          label: 'apply_coupon_code_success_saas',
        });
      });
    });

    describe('when applying an invalid promo code', () => {
      let promoCodeInput;
      let invoicePreviewSpy;

      beforeEach(async () => {
        invoicePreviewSpy = jest
          .fn()
          .mockResolvedValueOnce(mockInvoicePreviewWithDiscount) // { planId: 'thirdPlanId', quantity: 1 }
          .mockResolvedValueOnce(mockInvoicePreviewWithDiscount) // { planId: 'secondPlanId', quantity: 1 }
          .mockResolvedValueOnce(invalidPromoCodeResponse) // { planId: 'secondPlanId', quantity: 1, promoCode: 'promoCode' }
          .mockResolvedValueOnce(invalidPromoCodeResponse) // Extra mock that shouldn't happen to catch potential infinite loop
          .mockResolvedValueOnce(invalidPromoCodeResponse); // Extra mock that shouldn't happen to catch potential infinite loop
        await createComponent(invoicePreviewSpy);
        await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');

        promoCodeInput = findPromoCodeInput();
        promoCodeInput.vm.$emit('apply-promo-code', 'promoCode');

        await waitForPromises();
      });

      it('calls invoice preview API appropriately', () => {
        expect(invoicePreviewSpy).toHaveBeenCalledTimes(3);
        expect(invoicePreviewSpy).toHaveBeenNthCalledWith(1, {
          namespaceId: null,
          planId: 'thirdPlanId',
          quantity: 1,
        });
        expect(invoicePreviewSpy).toHaveBeenNthCalledWith(2, {
          namespaceId: null,
          planId: 'secondPlanId',
          quantity: 1,
        });
        expect(invoicePreviewSpy).toHaveBeenNthCalledWith(3, {
          namespaceId: null,
          planId: 'secondPlanId',
          quantity: 1,
          promoCode: 'promoCode',
        });
      });
    });

    describe('when promo code is updated after an invalid promo code is applied', () => {
      let promoCodeInput;
      const invoicePreviewSpy = jest.fn().mockResolvedValue(invalidPromoCodeResponse);

      beforeEach(async () => {
        await createComponent(invoicePreviewSpy);
        await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
        promoCodeInput = findPromoCodeInput();

        promoCodeInput.vm.$emit('apply-promo-code', 'promoCode');

        await waitForPromises();
      });

      it('shows error message for promo code', () => {
        expect(promoCodeInput.props('errorMessage')).toBe(INVALID_PROMO_CODE_ERROR_MESSAGE);
      });

      it('resets promo code value on update', () => {
        promoCodeInput.vm.$emit('promo-code-updated');

        expect(invoicePreviewSpy).toHaveBeenCalledWith({
          namespaceId: null,
          planId: 'secondPlanId',
          quantity: 1,
        });
      });
    });

    it('shows error message when promo code is applied without valid users', async () => {
      await createComponent();
      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
      await store.commit(types.UPDATE_NUMBER_OF_USERS, 0);

      const promoCodeInput = findPromoCodeInput();
      promoCodeInput.vm.$emit('apply-promo-code', 'promoCode');

      await waitForPromises();

      expect(promoCodeInput.props('errorMessage')).toBe(PROMO_CODE_USER_QUANTITY_ERROR_MESSAGE);
    });

    it('resets error message when quantity is specified after promo code is applied without valid users', async () => {
      await createComponent();
      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
      await store.commit(types.UPDATE_NUMBER_OF_USERS, 0);

      const promoCodeInput = findPromoCodeInput();
      promoCodeInput.vm.$emit('apply-promo-code', 'promoCode');

      await waitForPromises();
      await store.commit(types.UPDATE_NUMBER_OF_USERS, 1);

      expect(promoCodeInput.props('errorMessage')).toBe('');
    });
  });

  describe('promotional offer text', () => {
    it('shows promotional offer text when present', async () => {
      createComponent();

      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');
      await waitForPromises();

      expect(findPromotionalOfferText().text()).toBe(promotionalOfferText);
    });

    it('does not show promotional offer text when not present', async () => {
      createComponent();

      await store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');
      await waitForPromises();

      expect(findPromotionalOfferText().exists()).toBe(false);
    });

    it('does not show promotional offer text when loading', async () => {
      createComponent();

      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');

      expect(findPromotionalOfferText().exists()).toBe(false);
    });
  });

  describe('when use_invoice_preview_api_in_saas_purchase feature flag is disabled', () => {
    beforeEach(async () => {
      gon.features = { useInvoicePreviewApiInSaasPurchase: false };
      await store.commit(types.UPDATE_SELECTED_GROUP, 132);
      return createComponent(null, false);
    });

    it('displays the chosen plan', () => {
      expect(selectedPlan()).toContain('Gold plan');
    });

    it('displays the correct formatted amount price per user', () => {
      expect(perUserPriceInfo()).toBe('$1,188 per user per year');
    });

    it('displays the correct formatted total amount', () => {
      expect(totalPriceToBeCharged()).toBe('$1,188');
    });

    it('does not call invoice preview API', () => {
      expect(invoicePreviewQuerySpy).not.toHaveBeenCalled();
    });

    describe('when changing plan', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
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

      it('does not call invoice preview API', () => {
        expect(invoicePreviewQuerySpy).not.toHaveBeenCalled();
      });
    });

    describe('when changing users', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 3);
      });

      it('displays the chosen plan', () => {
        expect(selectedPlan()).toContain('Gold plan');
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
        expect(invoicePreviewQuerySpy).not.toHaveBeenCalled();
      });
    });
  });
});
