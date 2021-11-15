import { createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrderSummary from 'ee/subscriptions/buy_addons_shared/components/order_summary.vue';
import subscriptionsResolvers from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import {
  mockCiMinutesPlans,
  mockParsedNamespaces,
  stateData as mockStateData,
} from 'ee_jest/subscriptions/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';

const localVue = createLocalVue();
localVue.use(VueApollo);

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

  const createMockApolloProvider = (stateData = {}) => {
    const mockApollo = createMockApollo([], resolvers);
    const data = merge({}, mockStateData, initialStateData, stateData);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data,
    });
    return mockApollo;
  };

  const createComponent = (stateData) => {
    const apolloProvider = createMockApolloProvider(stateData);
    wrapper = shallowMountExtended(OrderSummary, {
      localVue,
      apolloProvider,
      propsData: {
        plan: mockCiMinutesPlans[0],
        title: "%{name}'s CI minutes",
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('the default plan', () => {
    beforeEach(() => {
      createComponent({
        subscription: { quantity: 1 },
      });
    });

    it('displays the title', () => {
      expect(findTitle().text()).toMatchInterpolatedText("Gitlab Org's CI minutes");
    });
  });

  describe('when quantity is greater than zero', () => {
    beforeEach(() => {
      createComponent({
        subscription: { quantity: 3 },
      });
    });

    it('renders amount', () => {
      expect(findAmount().text()).toBe('$30');
    });
  });

  describe('when quantity is less than or equal to zero', () => {
    beforeEach(() => {
      createComponent({
        subscription: { quantity: 0 },
      });
    });

    it('does not render amount', () => {
      expect(findAmount().text()).toBe('-');
    });
  });
});
