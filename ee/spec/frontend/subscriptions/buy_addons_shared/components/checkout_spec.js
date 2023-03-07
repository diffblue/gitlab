import Vue from 'vue';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import BillingAddress from 'jh_else_ee/vue_shared/purchase_flow/components/checkout/billing_address.vue';
import OrderConfirmation from 'ee/vue_shared/purchase_flow/components/checkout/confirm_order.vue';
import PaymentMethod from 'ee/vue_shared/purchase_flow/components/checkout/payment_method.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Checkout from 'ee/subscriptions/buy_addons_shared/components/checkout.vue';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import {
  mockCiMinutesPlans,
  mockParsedNamespaces,
  stateData as mockStateData,
} from 'ee_jest/subscriptions/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Checkout', () => {
  let wrapper;
  let updateState = jest.fn();

  const [plan] = mockCiMinutesPlans;
  const selectedNamespaceId = mockParsedNamespaces[0].id;
  const initialStateData = {
    eligibleNamespaces: mockParsedNamespaces,
    selectedNamespaceId,
    subscription: {},
  };

  const findBillingAddress = () => wrapper.findComponent(BillingAddress);
  const findOrderConfirmation = () => wrapper.findComponent(OrderConfirmation);
  const findPaymentMethod = () => wrapper.findComponent(PaymentMethod);

  const createMockApolloProvider = (stateData = {}) => {
    const resolvers = { Mutation: { updateState } };
    const mockApollo = createMockApollo([], resolvers);
    const data = merge({}, mockStateData, initialStateData, stateData);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data,
    });
    return mockApollo;
  };

  const createComponent = (stateData = {}) => {
    const apolloProvider = createMockApolloProvider(stateData);
    wrapper = shallowMountExtended(Checkout, {
      apolloProvider,
      propsData: {
        plan,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when mounted', () => {
    it('invokes the mutation with the correct params', () => {
      const { id, isAddon } = plan;

      expect(updateState).toHaveBeenNthCalledWith(
        1,
        expect.any(Object),
        { input: { selectedPlan: { id, isAddon } } },
        expect.any(Object),
        expect.any(Object),
      );
    });

    it('renders a Billing Address Component', () => {
      expect(findBillingAddress().exists()).toBe(true);
    });

    it('renders a Order Confirmation Component', () => {
      expect(findOrderConfirmation().exists()).toBe(true);
    });

    it('renders a Payment Method Component', () => {
      expect(findPaymentMethod().exists()).toBe(true);
    });
  });

  describe('when the mutation fails', () => {
    const error = new Error('Yikes!');

    beforeEach(() => {
      updateState = jest.fn().mockRejectedValue(error);
      createComponent();

      return waitForPromises();
    });

    it('emits an `error` event', () => {
      expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
    });
  });

  describe.each([findBillingAddress, findPaymentMethod, findOrderConfirmation])(
    'when %s emits error',
    (findMethod) => {
      const error = new Error('Yikes!');

      beforeEach(async () => {
        updateState = jest.fn().mockResolvedValue('');
        createComponent();

        await waitForPromises();

        findMethod().vm.$emit(PurchaseEvent.ERROR, error);
      });

      it('emits an `error` event', () => {
        expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
      });
    },
  );
});
