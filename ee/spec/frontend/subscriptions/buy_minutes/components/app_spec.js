import { GlEmptyState } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Checkout from 'ee/subscriptions/buy_addons_shared/components/checkout.vue';
import AddonPurchaseDetails from 'ee/subscriptions/buy_addons_shared/components/checkout/addon_purchase_details.vue';
import App from 'ee/subscriptions/buy_minutes/components/app.vue';
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { planTags } from '../../../../../app/assets/javascripts/subscriptions/buy_addons_shared/constants';
import { createMockApolloProvider } from '../spec_helper';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('App', () => {
  let wrapper;

  function createComponent(apolloProvider) {
    return shallowMountExtended(App, {
      localVue,
      propsData: { plan: planTags.CI_1000_MINUTES_PLAN },
      apolloProvider,
      stubs: {
        Checkout,
        AddonPurchaseDetails,
      },
    });
  }

  const findQuantityText = () => wrapper.findByTestId('addon-quantity-text');
  const findSummaryLabel = () => wrapper.findByTestId('summary-label');
  const findSummaryTotal = () => wrapper.findByTestId('summary-total');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when data is received', () => {
    it('should display the StepOrderApp', async () => {
      const mockApollo = createMockApolloProvider();
      wrapper = createComponent(mockApollo);
      await waitForPromises();

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(true);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(false);
    });
  });

  describe('when data is not received', () => {
    it('should display the GlEmptyState for empty data', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: null }),
      });
      wrapper = createComponent(mockApollo);
      await waitForPromises();

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('should display the GlEmptyState for empty plans', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: null } }),
      });
      wrapper = createComponent(mockApollo);
      await waitForPromises();

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('should display the GlEmptyState for plans data of wrong type', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: {} } }),
      });
      wrapper = createComponent(mockApollo);
      await waitForPromises();

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('when an error is received', () => {
    it('should display the GlEmptyState', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockRejectedValue(new Error('An error happened!')),
      });
      wrapper = createComponent(mockApollo);
      await waitForPromises();

      expect(wrapper.findComponent(StepOrderApp).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('labels', () => {
    it('are shown correctly for 1 pack', async () => {
      const mockApollo = createMockApolloProvider();
      wrapper = createComponent(mockApollo);
      await waitForPromises();

      expect(findQuantityText().exists()).toBe(true);
      expect(findQuantityText().text()).toMatchInterpolatedText(
        'x 1,000 minutes per pack = 1,000 CI minutes',
      );

      expect(findSummaryLabel().exists()).toBe(true);
      expect(findSummaryLabel().text()).toBe('1 CI minute pack');

      expect(findSummaryTotal().exists()).toBe(true);
      expect(findSummaryTotal().text()).toBe('Total minutes: 1,000');
    });

    it('are shown correctly for 2 packs', async () => {
      const mockApollo = createMockApolloProvider({}, { quantity: 2 });
      wrapper = createComponent(mockApollo);
      await waitForPromises();

      expect(findQuantityText().exists()).toBe(true);
      expect(findQuantityText().text()).toMatchInterpolatedText(
        'x 1,000 minutes per pack = 2,000 CI minutes',
      );

      expect(findSummaryLabel().exists()).toBe(true);
      expect(findSummaryLabel().text()).toBe('2 CI minute packs');

      expect(findSummaryTotal().exists()).toBe(true);
      expect(findSummaryTotal().text()).toBe('Total minutes: 2,000');
    });
  });
});
