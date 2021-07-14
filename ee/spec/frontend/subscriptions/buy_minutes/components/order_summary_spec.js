import { mount, createLocalVue } from '@vue/test-utils';
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

    wrapper = mount(OrderSummary, {
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

    it('displays the chosen plan', () => {
      expect(wrapper.find('.js-selected-plan').text()).toMatchInterpolatedText(
        '1000 CI minutes pack plan (x1)',
      );
    });

    it('displays the correct formatted amount price per pack', () => {
      expect(wrapper.find('.js-per-unit').text()).toContain('$10 per pack per year');
    });

    it('displays the correct formatted total amount', () => {
      expect(wrapper.find('.js-total-amount').text()).toContain('$10');
    });
  });

  describe('changing quantity', () => {
    beforeEach(() => {
      createComponent({
        subscription: { quantity: 3 },
      });
    });

    it('displays the correct quantity', () => {
      expect(wrapper.find('.js-quantity').text()).toContain('(x3)');
    });

    it('displays the correct formatted amount price per unit', () => {
      expect(wrapper.find('.js-per-unit').text()).toContain('$10 per pack per year');
    });

    it('displays the correct multiplied formatted amount of the chosen plan', () => {
      expect(wrapper.find('.js-amount').text()).toContain('$30');
    });

    it('displays the correct formatted total amount', () => {
      expect(wrapper.find('.js-total-amount').text()).toContain('$30');
    });

    describe('tax rate', () => {
      beforeEach(() => {
        createComponent();
      });

      describe('a tax rate of 0', () => {
        it('should not display the total amount excluding vat', () => {
          expect(wrapper.find('.js-total-ex-vat').exists()).toBe(false);
        });

        it('should not display the vat amount', () => {
          expect(wrapper.find('.js-vat').exists()).toBe(false);
        });
      });
    });
  });
});
