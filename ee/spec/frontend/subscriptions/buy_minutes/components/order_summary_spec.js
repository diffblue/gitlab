import { shallowMount, createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import OrderSummary from 'ee/subscriptions/buy_minutes/components/order_summary.vue';
import subscriptionsResolvers from 'ee/subscriptions/buy_minutes/graphql/resolvers';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import {
  mockCiMinutesPlans,
  mockParsedNamespaces,
  stateData as mockStateData,
} from 'ee_jest/subscriptions/buy_minutes/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Order Summary', () => {
  const resolvers = { ...purchaseFlowResolvers, ...subscriptionsResolvers };
  const initialStateData = {
    selectedPlanId: 'ciMinutesPackPlanId',
    namespaces: [mockParsedNamespaces[0]],
    subscription: {
      namespaceId: mockParsedNamespaces[0].id,
    },
  };
  let wrapper;

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

    wrapper = shallowMount(OrderSummary, {
      localVue,
      apolloProvider,
      propsData: {
        plan: mockCiMinutesPlans[0],
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
        selectedPlanId: 'ciMinutesPackPlanId',
      });
    });

    it('displays the title', () => {
      expect(wrapper.find('[data-testid="title"]').text()).toMatchInterpolatedText(
        "Gitlab Org's CI minutes",
      );
    });
  });

  describe('when quantity is greater than zero', () => {
    beforeEach(() => {
      createComponent({
        subscription: { quantity: 3 },
      });
    });

    it('renders amount', () => {
      expect(wrapper.find('[data-testid="amount"]').text()).toBe('$30');
    });
  });

  describe('when quantity is less than or equal to zero', () => {
    beforeEach(() => {
      createComponent({
        subscription: { quantity: 0 },
      });
    });

    it('does not render amount', () => {
      expect(wrapper.find('[data-testid="amount"]').text()).toBe('-');
    });
  });
});
