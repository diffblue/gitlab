import Vue from 'vue';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrderSummary from 'ee/subscriptions/buy_addons_shared/components/order_summary.vue';
import subscriptionsResolvers from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import {
  mockStoragePlans,
  mockParsedNamespaces,
  mockOrderPreview,
  stateData as mockStateData,
} from 'ee_jest/subscriptions/mock_data';
import createMockApollo, { createMockClient } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import orderPreviewQuery from 'ee/subscriptions/graphql/queries/order_preview.customer.query.graphql';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

Vue.use(VueApollo);

describe('Order Summary', () => {
  const resolvers = { ...purchaseFlowResolvers, ...subscriptionsResolvers };
  const selectedNamespaceId = mockParsedNamespaces[0].id;
  const initialStateData = {
    eligibleNamespaces: mockParsedNamespaces,
    selectedNamespaceId,
    subscription: {},
  };
  let wrapper;

  const findAmount = () => wrapper.findByTestId('amount');
  const findTitle = () => wrapper.findByTestId('title');

  const orderPreviewHandlerMock = jest
    .fn()
    .mockResolvedValue({ data: { orderPreview: mockOrderPreview } });

  const createMockApolloProvider = (stateData = {}, mockRequest = {}) => {
    const mockApollo = createMockApollo([], resolvers);
    const data = merge({}, mockStateData, initialStateData, stateData);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data,
    });
    mockApollo.clients[CUSTOMERSDOT_CLIENT] = createMockClient([[orderPreviewQuery, mockRequest]]);
    return mockApollo;
  };

  const createComponent = (apolloProvider, props) => {
    wrapper = shallowMountExtended(OrderSummary, {
      apolloProvider,
      propsData: {
        plan: mockStoragePlans[0],
        title: "%{name}'s storage subscription",
        ...props,
      },
    });
  };

  describe('the default plan', () => {
    beforeEach(() => {
      const apolloProvider = createMockApolloProvider({ subscription: { quantity: 1 } });
      createComponent(apolloProvider);
    });

    it('displays the title', () => {
      expect(findTitle().text()).toMatchInterpolatedText("Gitlab Org's storage subscription");
    });
  });

  describe('when quantity is greater than zero', () => {
    beforeEach(() => {
      const apolloProvider = createMockApolloProvider({ subscription: { quantity: 3 } });
      createComponent(apolloProvider);
    });

    it('renders amount', () => {
      expect(findAmount().text()).toBe('$180');
    });
  });

  describe('when quantity is less than or equal to zero', () => {
    beforeEach(() => {
      const apolloProvider = createMockApolloProvider({
        subscription: { quantity: 0 },
      });
      createComponent(apolloProvider);
    });

    it('does not render amount', () => {
      expect(findAmount().text()).toBe('-');
    });
  });

  describe('when subscription has expiration date', () => {
    describe('calls api that returns prorated amount', () => {
      beforeEach(async () => {
        const apolloProvider = createMockApolloProvider(
          { subscription: { quantity: 1 } },
          orderPreviewHandlerMock,
        );
        createComponent(apolloProvider, { purchaseHasExpiration: true });
        await waitForPromises();
      });

      it('renders prorated amount', () => {
        expect(findAmount().text()).toBe('$59.67');
      });
    });

    describe('calls api that returns empty value', () => {
      beforeEach(async () => {
        const orderPreviewQueryMock = jest.fn().mockResolvedValue({ data: { orderPreview: null } });
        const apolloProvider = createMockApolloProvider(
          { subscription: { quantity: 1 } },
          orderPreviewQueryMock,
        );
        createComponent(apolloProvider, { purchaseHasExpiration: true });
        await waitForPromises();
      });

      it('renders default amount without proration from the state', () => {
        expect(findAmount().text()).toBe('$60');
      });
    });

    describe('calls api that returns no data', () => {
      it('does not render amount', () => {
        const orderPreviewQueryMock = jest.fn().mockResolvedValue({ data: null });
        const apolloProvider = createMockApolloProvider(
          { subscription: { quantity: 1 } },
          orderPreviewQueryMock,
        );
        createComponent(apolloProvider, { purchaseHasExpiration: true });

        expect(findAmount().text()).toBe('-');
      });
    });

    describe('calls api that returns an error', () => {
      const error = new Error('An error happened!');

      beforeEach(() => {
        const orderPreviewQueryMock = jest.fn().mockRejectedValue(error);
        const apolloProvider = createMockApolloProvider(
          { subscription: { quantity: 1 } },
          orderPreviewQueryMock,
        );
        createComponent(apolloProvider, { purchaseHasExpiration: true });
        return waitForPromises();
      });

      it('does not render amount', () => {
        expect(findAmount().text()).toBe('-');
      });

      it('should emit `error` event', () => {
        expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
      });
    });

    describe('when api is loading', () => {
      beforeEach(() => {
        const orderPreviewQueryMock = jest.fn().mockResolvedValue(new Promise(() => {}));
        const apolloProvider = createMockApolloProvider(
          { subscription: { quantity: 1 } },
          orderPreviewQueryMock,
        );
        createComponent(apolloProvider, { purchaseHasExpiration: true });
      });

      it('does not render amount when api is loading', () => {
        expect(findAmount().text()).toBe('-');
      });
    });

    describe('when subscription quantity is 0', () => {
      beforeEach(() => {
        const apolloProvider = createMockApolloProvider(
          { subscription: { quantity: 0 } },
          orderPreviewHandlerMock,
        );
        createComponent(apolloProvider, { purchaseHasExpiration: true });
      });

      it('does not call api', () => {
        expect(orderPreviewHandlerMock).not.toHaveBeenCalled();
      });
    });
  });
});
