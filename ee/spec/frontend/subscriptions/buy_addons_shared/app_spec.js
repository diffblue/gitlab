import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { pick } from 'lodash';
import { logError } from '~/lib/logger';
import {
  I18N_API_ERROR,
  I18N_CI_1000_MINUTES_PLAN,
  I18N_STORAGE_PLAN,
  planTags,
} from 'ee/subscriptions/buy_addons_shared/constants';
import Checkout from 'ee/subscriptions/buy_addons_shared/components/checkout.vue';
import AddonPurchaseDetails from 'ee/subscriptions/buy_addons_shared/components/checkout/addon_purchase_details.vue';
import OrderSummary from 'ee/subscriptions/buy_addons_shared/components/order_summary.vue';
import SummaryDetails from 'ee/subscriptions/buy_addons_shared/components/order_summary/summary_details.vue';
import App from 'ee/subscriptions/buy_addons_shared/components/app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockApolloProvider } from 'ee_jest/subscriptions/spec_helper';
import { mockCiMinutesPlans, mockStoragePlans } from 'ee_jest/subscriptions/mock_data';
import ErrorAlert from 'ee/vue_shared/purchase_flow/components/checkout/error_alert.vue';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

Vue.use(VueApollo);

jest.mock('~/lib/logger');

describe('Buy Addons Shared App', () => {
  let wrapper;

  const createComponent = (apolloProvider, injectedProps) => {
    wrapper = shallowMountExtended(App, {
      apolloProvider,
      provide: injectedProps,
      stubs: {
        Checkout,
        AddonPurchaseDetails,
        OrderSummary,
        SummaryDetails,
      },
    });
    return waitForPromises();
  };

  const getStoragePlan = () => pick(mockStoragePlans[0], ['id', 'code', 'pricePerYear', 'name']);
  const getCiMinutesPlan = () =>
    pick(mockCiMinutesPlans[0], ['id', 'code', 'pricePerYear', 'name']);
  const findCheckout = () => wrapper.findComponent(Checkout);
  const findOrderSummary = () => wrapper.findComponent(OrderSummary);
  const findErrorAlert = () => wrapper.findComponent(ErrorAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPriceLabel = () => wrapper.findByTestId('price-per-unit');
  const findQuantityText = () => wrapper.findByTestId('addon-quantity-text');
  const findRootElement = () => wrapper.findByTestId('buy-addons-shared');
  const findSummaryLabel = () => wrapper.findByTestId('summary-label');
  const findSummaryTotal = () => wrapper.findByTestId('summary-total');

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException');
  });

  describe('Storage', () => {
    const injectedProps = {
      tags: [planTags.STORAGE_PLAN],
      i18n: I18N_STORAGE_PLAN,
    };
    describe('when data is received', () => {
      beforeEach(async () => {
        const plansQueryMock = jest.fn().mockResolvedValue({ data: { plans: mockStoragePlans } });
        const mockApollo = createMockApolloProvider({ plansQueryMock });
        await createComponent(mockApollo, injectedProps);
      });

      it('displays the root element', () => {
        expect(findRootElement().exists()).toBe(true);
      });

      it('hides the empty state component', () => {
        expect(findEmptyState().exists()).toBe(false);
      });

      it('provides the correct props to checkout', () => {
        expect(findCheckout().props()).toMatchObject({
          plan: { ...getStoragePlan, isAddon: true },
        });
      });

      it('provides the correct props to OrderSummary', () => {
        expect(findOrderSummary().props()).toMatchObject({
          plan: { ...getStoragePlan, isAddon: true },
          title: I18N_STORAGE_PLAN.title,
        });
      });

      it('does not display the error alert', () => {
        expect(findErrorAlert().exists()).toBe(false);
      });

      describe('when OrderSummary emits an `error` event', () => {
        const error = new Error(I18N_API_ERROR);

        beforeEach(() => {
          findOrderSummary().vm.$emit(PurchaseEvent.ERROR, error);
          return nextTick();
        });

        it('passes the correct props to the alert', () => {
          expect(findErrorAlert().props('error')).toBe(error);
        });

        it('captures the error', () => {
          expect(Sentry.captureException.mock.calls[0][0]).toBe(error);
        });

        it('logs the error', () => {
          expect(logError).toHaveBeenCalledWith(error);
        });
      });
    });

    describe('when data is not received', () => {
      it('should display the GlEmptyState for empty data', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockResolvedValue({ data: null }),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should display the GlEmptyState for empty plans', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: null } }),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should display the GlEmptyState for plans data of wrong type', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: {} } }),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('when an error is received', () => {
      it('should display the GlEmptyState', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockRejectedValue(new Error('An error happened!')),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('labels', () => {
      const plansQueryMock = jest.fn().mockResolvedValue({ data: { plans: mockStoragePlans } });
      it('shows labels correctly for 1 pack', async () => {
        const mockApollo = createMockApolloProvider({ plansQueryMock });
        await createComponent(mockApollo, injectedProps);

        expect(findQuantityText().text()).toMatchInterpolatedText(
          'x 10 GB per pack = 10 GB of storage',
        );
        expect(findSummaryLabel().text()).toBe('1 storage pack');
        expect(findSummaryTotal().text()).toBe('Total storage: 10 GB');
        expect(findPriceLabel().text()).toBe('$60 per 10 GB storage pack per year');
        expect(wrapper.text()).toMatchSnapshot();
      });

      it('shows labels correctly for 2 packs', async () => {
        const mockApollo = createMockApolloProvider({ plansQueryMock }, { quantity: 2 });
        await createComponent(mockApollo, injectedProps);

        expect(findQuantityText().text()).toMatchInterpolatedText(
          'x 10 GB per pack = 20 GB of storage',
        );
        expect(findSummaryLabel().text()).toBe('2 storage packs');
        expect(findSummaryTotal().text()).toBe('Total storage: 20 GB');
        expect(findPriceLabel().text()).toBe('$60 per 10 GB storage pack per year');
        expect(wrapper.text()).toMatchSnapshot();
      });

      it('does not show labels if input is invalid', async () => {
        const mockApollo = createMockApolloProvider({ plansQueryMock }, { quantity: -1 });
        await createComponent(mockApollo, injectedProps);

        expect(findQuantityText().text()).toMatchInterpolatedText('x 10 GB per pack');
        expect(wrapper.text()).toMatchSnapshot();
      });
    });
  });

  describe('CI Minutes', () => {
    const injectedProps = {
      tags: [planTags.CI_1000_MINUTES_PLAN],
      i18n: I18N_CI_1000_MINUTES_PLAN,
    };

    describe('when data is received', () => {
      beforeEach(async () => {
        const plansQueryMock = jest.fn().mockResolvedValue({ data: { plans: mockCiMinutesPlans } });
        const mockApollo = createMockApolloProvider({ plansQueryMock });
        await createComponent(mockApollo, injectedProps);
      });

      it('should display the root element', () => {
        expect(findRootElement().exists()).toBe(true);
        expect(findEmptyState().exists()).toBe(false);
      });

      it('provides the correct props to checkout', () => {
        expect(findCheckout().props()).toMatchObject({
          plan: { ...getCiMinutesPlan, isAddon: true },
        });
      });

      it('provides the correct props to OrderSummary', () => {
        expect(findOrderSummary().props()).toMatchObject({
          plan: { ...getCiMinutesPlan, isAddon: true },
          title: I18N_CI_1000_MINUTES_PLAN.title,
        });
      });
    });

    describe('when data is not received', () => {
      it('should display the GlEmptyState for empty data', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockResolvedValue({ data: null }),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should display the GlEmptyState for empty plans', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: null } }),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should display the GlEmptyState for plans data of wrong type', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: {} } }),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('when an error is received', () => {
      it('should display the GlEmptyState', async () => {
        const mockApollo = createMockApolloProvider({
          plansQueryMock: jest.fn().mockRejectedValue(new Error('An error happened!')),
        });
        await createComponent(mockApollo, injectedProps);

        expect(findRootElement().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('labels', () => {
      const plansQueryMock = jest.fn().mockResolvedValue({ data: { plans: mockCiMinutesPlans } });
      it('shows labels correctly for 1 pack', async () => {
        const mockApollo = createMockApolloProvider({ plansQueryMock });
        await createComponent(mockApollo, injectedProps);

        expect(findQuantityText().text()).toMatchInterpolatedText(
          'x 1,000 minutes per pack = 1,000 CI minutes',
        );
        expect(findSummaryLabel().text()).toBe('1 CI minute pack');
        expect(findSummaryTotal().text()).toBe('Total minutes: 1,000');
        expect(findPriceLabel().text()).toBe('$10 per pack of 1,000 minutes');
        expect(wrapper.text()).toMatchSnapshot();
      });

      it('shows labels correctly for 2 packs', async () => {
        const mockApollo = createMockApolloProvider({ plansQueryMock }, { quantity: 2 });
        await createComponent(mockApollo, injectedProps);

        expect(findQuantityText().text()).toMatchInterpolatedText(
          'x 1,000 minutes per pack = 2,000 CI minutes',
        );
        expect(findSummaryLabel().text()).toBe('2 CI minute packs');
        expect(findSummaryTotal().text()).toBe('Total minutes: 2,000');
        expect(findPriceLabel().text()).toBe('$10 per pack of 1,000 minutes');
        expect(wrapper.text()).toMatchSnapshot();
      });

      it('does not show labels if input is invalid', async () => {
        const mockApollo = createMockApolloProvider({ plansQueryMock }, { quantity: -1 });
        await createComponent(mockApollo, injectedProps);

        expect(findQuantityText().text()).toMatchInterpolatedText('x 1,000 minutes per pack');
        expect(wrapper.text()).toMatchSnapshot();
      });
    });
  });
});
