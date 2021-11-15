import { GlEmptyState } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { pick } from 'lodash';
import { I18N_STORAGE_TITLE } from 'ee/subscriptions/buy_addons_shared/constants';
import Checkout from 'ee/subscriptions/buy_addons_shared/components/checkout.vue';
import AddonPurchaseDetails from 'ee/subscriptions/buy_addons_shared/components/checkout/addon_purchase_details.vue';
import OrderSummary from 'ee/subscriptions/buy_addons_shared/components/order_summary.vue';
import SummaryDetails from 'ee/subscriptions/buy_addons_shared/components/order_summary/summary_details.vue';
import App from 'ee/subscriptions/buy_storage/components/app.vue';
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockApolloProvider } from 'ee_jest/subscriptions/spec_helper';
import { mockStoragePlans } from 'ee_jest/subscriptions/mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Buy Storage App', () => {
  let wrapper;

  function createComponent(apolloProvider) {
    wrapper = shallowMountExtended(App, {
      localVue,
      apolloProvider,
      stubs: {
        Checkout,
        AddonPurchaseDetails,
        OrderSummary,
        SummaryDetails,
      },
    });
    return waitForPromises();
  }

  const getStoragePlan = () => pick(mockStoragePlans[0], ['id', 'code', 'pricePerYear', 'name']);
  const findCheckout = () => wrapper.findComponent(Checkout);
  const findOrderSummary = () => wrapper.findComponent(OrderSummary);
  const findPriceLabel = () => wrapper.findByTestId('price-per-unit');
  const findQuantityText = () => wrapper.findByTestId('addon-quantity-text');
  const findSummaryLabel = () => wrapper.findByTestId('summary-label');
  const findSummaryTotal = () => wrapper.findByTestId('summary-total');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when data is received', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider();
      return createComponent(mockApollo);
    });

    it('should display the StepOrderApp', () => {
      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(true);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(false);
    });

    it('provides the correct props to checkout', () => {
      expect(findCheckout().props()).toMatchObject({
        plan: { ...getStoragePlan, isAddon: true },
      });
    });

    it('provides the correct props to order summary', () => {
      expect(findOrderSummary().props()).toMatchObject({
        plan: { ...getStoragePlan, isAddon: true },
        title: I18N_STORAGE_TITLE,
      });
    });
  });

  describe('when data is not received', () => {
    it('should display the GlEmptyState for empty data', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: null }),
      });
      await createComponent(mockApollo);

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('should display the GlEmptyState for empty plans', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: null } }),
      });
      await createComponent(mockApollo);

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('should display the GlEmptyState for plans data of wrong type', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: {} } }),
      });
      await createComponent(mockApollo);

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('when an error is received', () => {
    it('should display the GlEmptyState', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockRejectedValue(new Error('An error happened!')),
      });
      await createComponent(mockApollo);

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('labels', () => {
    it('shows labels correctly for 1 pack', async () => {
      const mockApollo = createMockApolloProvider();
      await createComponent(mockApollo);

      expect(findQuantityText().text()).toMatchInterpolatedText(
        'x 10 GB per pack = 10 GB of storage',
      );
      expect(findSummaryLabel().text()).toBe('1 storage pack');
      expect(findSummaryTotal().text()).toBe('Total storage: 10 GB');
      expect(findPriceLabel().text()).toBe('$10 per 10 GB storage per pack');
    });

    it('shows labels correctly for 2 packs', async () => {
      const mockApollo = createMockApolloProvider({}, { quantity: 2 });
      await createComponent(mockApollo);

      expect(findQuantityText().text()).toMatchInterpolatedText(
        'x 10 GB per pack = 20 GB of storage',
      );
      expect(findSummaryLabel().text()).toBe('2 storage packs');
      expect(findSummaryTotal().text()).toBe('Total storage: 20 GB');
    });

    it('does not show labels if input is invalid', async () => {
      const mockApollo = createMockApolloProvider({}, { quantity: -1 });
      await createComponent(mockApollo);

      expect(findQuantityText().text()).toMatchInterpolatedText('x 10 GB per pack');
    });
  });
});
