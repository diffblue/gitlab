import { mount, createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { resolvers } from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import PaymentMethod from 'ee/vue_shared/purchase_flow/components/checkout/payment_method.vue';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { stateData as initialStateData } from 'ee_jest/subscriptions/buy_minutes/mock_data';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Payment Method', () => {
  let wrapper;

  const createComponent = (apolloLocalState = {}) => {
    const apolloProvider = createMockApolloProvider(STEPS, STEPS[2], {
      ...resolvers,
    });
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data: merge({}, initialStateData, apolloLocalState),
    });

    return mount(PaymentMethod, {
      localVue,
      apolloProvider,
    });
  };

  beforeEach(() => {
    wrapper = createComponent({
      paymentMethod: {
        id: 'paymentMethodId',
        creditCardType: 'Visa',
        creditCardMaskNumber: '************4242',
        creditCardExpirationMonth: 12,
        creditCardExpirationYear: 2009,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('validations', () => {
    const isStepValid = () => wrapper.find(Step).props('isValid');

    it('should be valid when paymentMethodId is defined', () => {
      expect(isStepValid()).toBe(true);
    });

    it('should be invalid when paymentMethodId is undefined', () => {
      wrapper = createComponent({
        paymentMethod: { id: null },
      });

      expect(isStepValid()).toBe(false);
    });
  });

  describe('showing the summary', () => {
    it('should show the entered credit card details', () => {
      expect(wrapper.find('.js-summary-line-1').text()).toMatchInterpolatedText(
        'Visa ending in 4242',
      );
    });

    it('should show the entered credit card expiration date', () => {
      expect(wrapper.find('.js-summary-line-2').text()).toBe('Exp 12/09');
    });
  });
});
