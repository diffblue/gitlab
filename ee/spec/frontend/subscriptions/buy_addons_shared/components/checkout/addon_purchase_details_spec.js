import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { stateData as initialStateData } from 'ee_jest/subscriptions/mock_data';
import AddonPurchaseDetails from 'ee/subscriptions/buy_addons_shared/components/checkout/addon_purchase_details.vue';
import subscriptionsResolvers from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(VueApollo);

describe('AddonPurchaseDetails', () => {
  const resolvers = { ...purchaseFlowResolvers, ...subscriptionsResolvers };
  let wrapper;

  const createMockApolloProvider = (stateData = {}) => {
    const mockApollo = createMockApollo([], resolvers);
    const data = merge({}, initialStateData, stateData);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data,
    });
    return mockApollo;
  };

  const createComponent = (stateData = {}, props = {}) => {
    const apolloProvider = createMockApolloProvider(stateData);
    wrapper = mountExtended(AddonPurchaseDetails, {
      apolloProvider,
      stubs: {
        Step,
      },
      propsData: {
        productLabel: 'CI minute pack',
        quantity: 10,
        packsFormula: 'x %{packQuantity} minutes per pack = %{strong}',
        quantityText: '%{quantity} CI minutes',
        totalPurchase: 'Total minutes: %{quantity}',
        ...props,
      },
    });
  };

  const findQuantity = () => wrapper.findComponent({ ref: 'quantity' });
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findProductLabel = () => wrapper.findByTestId('product-label');
  const isStepValid = () => wrapper.findComponent(Step).props('isValid');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets the min quantity to 1', () => {
    expect(findQuantity().attributes('min')).toBe('1');
  });

  it('shows the correct product label', () => {
    expect(findProductLabel().text()).toBe('CI minute pack');
  });

  it('is valid', () => {
    expect(isStepValid()).toBe(true);
  });

  it('is invalid when quantity is less than 1', async () => {
    createComponent(
      {
        subscription: { namespaceId: 483 },
      },
      { quantity: 0 },
    );

    expect(isStepValid()).toBe(false);
  });

  describe('alert', () => {
    it('is hidden if no props passed', () => {
      expect(findGlAlert().exists()).toBe(false);
    });

    it('is hidden when props are set to false', () => {
      createComponent({}, { showAlert: false, alertText: 'Alert text about your purchase' });
      expect(findGlAlert().exists()).toBe(false);
    });

    it('is hidden when alertText prop is missing', () => {
      createComponent({}, { showAlert: true });
      expect(findGlAlert().exists()).toBe(false);
    });

    it('is shown', () => {
      createComponent({}, { showAlert: true, alertText: 'Alert text about your purchase' });
      expect(findGlAlert().isVisible()).toBe(true);
      expect(findGlAlert().text()).toMatchInterpolatedText('Alert text about your purchase');
    });
  });
});
