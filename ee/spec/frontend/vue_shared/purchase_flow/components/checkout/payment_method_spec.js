import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import {
  mockParsedNamespaces,
  stateData as initialStateData,
} from 'ee_jest/subscriptions/mock_data';
import { gitLabResolvers } from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import PaymentMethod from 'ee/vue_shared/purchase_flow/components/checkout/payment_method.vue';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import Zuora from 'ee/vue_shared/purchase_flow/components/checkout/zuora.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

Vue.use(VueApollo);

describe('Payment Method', () => {
  let wrapper;

  const findCCDetails = () => wrapper.findByTestId('card-details');
  const findCCExpiration = () => wrapper.findByTestId('card-expiration');

  const findZuora = () => wrapper.findComponent(Zuora);

  const isStepValid = () => wrapper.findComponent(Step).props('isValid');
  const createComponent = (apolloLocalState = {}) => {
    const apolloProvider = createMockApolloProvider(STEPS, STEPS[2], gitLabResolvers);
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data: merge({}, initialStateData, apolloLocalState),
    });

    return mountExtended(PaymentMethod, {
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

  describe('payment method step', () => {
    it('is valid when paymentMethodId is defined', () => {
      expect(isStepValid()).toBe(true);
    });

    it('is invalid when paymentMethodId is undefined', () => {
      wrapper = createComponent({
        paymentMethod: { id: null },
      });

      expect(isStepValid()).toBe(false);
    });
  });

  describe('summary', () => {
    it('shows the entered credit card details', () => {
      expect(findCCDetails().text()).toMatchInterpolatedText('Visa ending in 4242');
    });

    it('shows the entered credit card expiration date', () => {
      expect(findCCExpiration().text()).toBe('Exp 12/09');
    });
  });

  describe('Zuora Component', () => {
    const eligibleNamespaces = mockParsedNamespaces;
    const active = true;
    const activeStep = STEPS[2];

    describe('when the selected namespace exists', () => {
      describe('when it has an account id', () => {
        it('has the selected account id', () => {
          const { accountId, id } = mockParsedNamespaces[0];
          const selectedNamespaceId = `${id}`;
          wrapper = createComponent({ eligibleNamespaces, selectedNamespaceId, activeStep });

          expect(findZuora().props()).toMatchObject({ active, accountId });
        });
      });

      describe('when it has no account id', () => {
        it('has the default account id', () => {
          const { id } = mockParsedNamespaces[1];
          const selectedNamespaceId = `${id}`;
          wrapper = createComponent({ eligibleNamespaces, selectedNamespaceId, activeStep });

          expect(findZuora().props()).toMatchObject({ active, accountId: '' });
        });
      });
    });

    describe('when the selected namespace does not exists', () => {
      it('has the default account id', () => {
        const selectedNamespaceId = `000`;
        wrapper = createComponent({ eligibleNamespaces, selectedNamespaceId, activeStep });

        expect(findZuora().props()).toMatchObject({ active, accountId: '' });
      });
    });

    describe('when Zuora emits an error', () => {
      const error = new Error('An error!');

      it('emits an `error` event', () => {
        findZuora().vm.$emit(PurchaseEvent.ERROR, error);

        expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
      });
    });
  });
});
