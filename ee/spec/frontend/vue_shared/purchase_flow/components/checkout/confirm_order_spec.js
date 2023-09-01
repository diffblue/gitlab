import { v4 as uuid } from 'uuid';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Api from 'ee/api';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import ConfirmOrder from 'ee/vue_shared/purchase_flow/components/checkout/confirm_order.vue';
import { stateData as initialStateData, subscriptionName } from 'ee_jest/subscriptions/mock_data';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import * as UrlUtility from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

jest.mock('uuid');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');
jest.mock('ee/api.js');

Vue.use(VueApollo);

describe('Confirm Order', () => {
  let mockApolloProvider;
  let wrapper;

  const idempotencyKeyFirstAttempt = '123';
  const idempotencyKeySecondAttempt = '456';
  const location = 'group/location/path';

  const findRootElement = () => wrapper.findByTestId('confirm-order-root');
  const findConfirmButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = (options = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ConfirmOrder, {
        ...options,
      }),
    );
  };

  describe('when rendering', () => {
    describe('when receiving proper step data', () => {
      beforeEach(() => {
        mockApolloProvider = createMockApolloProvider(STEPS, 3);
        mockApolloProvider.clients.defaultClient.cache.writeQuery({
          query: stateQuery,
          data: { ...initialStateData, stepList: STEPS, activeStep: STEPS[3] },
        });
        createComponent({ apolloProvider: mockApolloProvider });
        return waitForPromises();
      });

      it('shows the text "Confirm purchase"', () => {
        expect(findConfirmButton().text()).toBe('Confirm purchase');
      });

      it('the loading indicator should not be visible', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    describe('when confirming the order', () => {
      beforeEach(async () => {
        mockApolloProvider = createMockApolloProvider([]);
        mockApolloProvider.clients.defaultClient.cache.writeQuery({
          query: stateQuery,
          data: { ...initialStateData, stepList: STEPS, activeStep: STEPS[3] },
        });
        uuid.mockReturnValue(idempotencyKeyFirstAttempt);
        Api.confirmOrder = jest.fn().mockReturnValue(new Promise(jest.fn()));
        createComponent({ apolloProvider: mockApolloProvider });
        await waitForPromises();
        findConfirmButton().vm.$emit('click');
      });

      it('calls the confirmOrder API method with the correct params', () => {
        expect(Api.confirmOrder).toHaveBeenCalledTimes(1);
        expect(Api.confirmOrder).toHaveBeenCalledWith({
          idempotency_key: idempotencyKeyFirstAttempt,
          setup_for_company: true,
          selected_group: '30',
          active_subscription: subscriptionName,
          new_user: false,
          redirect_after_success: '/path/to/redirect/',
          customer: {
            country: null,
            address_1: null,
            address_2: null,
            city: null,
            state: null,
            zip_code: 94100,
            company: null,
          },
          subscription: {
            plan_id: 1,
            is_addon: true,
            payment_method_id: 1,
            quantity: 1,
          },
        });
      });

      it('shows the text "Confirming..."', () => {
        expect(findConfirmButton().text()).toBe('Confirming...');
      });

      it('the loading indicator should be visible', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });

      describe('when confirm order succeeds', () => {
        beforeEach(async () => {
          uuid.mockReturnValue(idempotencyKeyFirstAttempt);
          Api.confirmOrder = jest.fn().mockResolvedValue({ data: { location } });
          createComponent({ apolloProvider: mockApolloProvider });
          await waitForPromises();
          findConfirmButton().vm.$emit('click');
        });

        it('does not change the idempotency key', async () => {
          findConfirmButton().vm.$emit('click');
          await waitForPromises();

          expect(Api.confirmOrder).toHaveBeenLastCalledWith(
            expect.objectContaining({
              idempotency_key: idempotencyKeyFirstAttempt,
            }),
          );
        });
      });
    });

    describe('when confirm order fails', () => {
      beforeEach(() => {
        mockApolloProvider = createMockApolloProvider(STEPS, 3);
        mockApolloProvider.clients.defaultClient.cache.writeQuery({
          query: stateQuery,
          data: { ...initialStateData, stepList: STEPS, activeStep: STEPS[3] },
        });
      });

      describe('with code: 4XX', () => {
        beforeEach(async () => {
          uuid
            .mockReturnValueOnce('000')
            .mockReturnValueOnce(idempotencyKeyFirstAttempt)
            .mockReturnValueOnce(idempotencyKeySecondAttempt);
          Api.confirmOrder = jest
            .fn()
            .mockRejectedValueOnce({ response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } })
            .mockRejectedValueOnce({ response: { status: HTTP_STATUS_FORBIDDEN } })
            .mockResolvedValue({ data: { location } });
          createComponent({ apolloProvider: mockApolloProvider });
          await waitForPromises();
          findConfirmButton().vm.$emit('click');
        });

        it('changes the idempotency key', async () => {
          expect(Api.confirmOrder).toHaveBeenNthCalledWith(
            1,
            expect.objectContaining({
              idempotency_key: idempotencyKeyFirstAttempt,
            }),
          );

          // Generates idempotency key after HTTP_STATUS_FORBIDDEN
          findConfirmButton().vm.$emit('click');
          await waitForPromises();
          // Invokes `confirmOrder` the last time
          findConfirmButton().vm.$emit('click');
          await waitForPromises();

          expect(Api.confirmOrder).toHaveBeenLastCalledWith(
            expect.objectContaining({
              idempotency_key: idempotencyKeySecondAttempt,
            }),
          );
        });
      });

      describe('with code: 5XX', () => {
        beforeEach(async () => {
          uuid
            .mockReturnValueOnce('000')
            .mockReturnValueOnce(idempotencyKeyFirstAttempt)
            .mockReturnValueOnce(idempotencyKeySecondAttempt);
          Api.confirmOrder = jest
            .fn()
            .mockRejectedValueOnce({ response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } })
            .mockResolvedValueOnce({ data: { location } });
          createComponent({ apolloProvider: mockApolloProvider });
          await waitForPromises();
          findConfirmButton().vm.$emit('click');
        });

        it('does not change the idempotency key', async () => {
          expect(Api.confirmOrder).toHaveBeenNthCalledWith(
            1,
            expect.objectContaining({
              idempotency_key: idempotencyKeyFirstAttempt,
            }),
          );

          findConfirmButton().vm.$emit('click');
          await waitForPromises();

          expect(Api.confirmOrder).toHaveBeenLastCalledWith(
            expect.objectContaining({
              idempotency_key: idempotencyKeyFirstAttempt,
            }),
          );
        });
      });
    });

    describe('when confirming the purchase', () => {
      beforeEach(() => {
        mockApolloProvider = createMockApolloProvider(STEPS, 3);
        mockApolloProvider.clients.defaultClient.cache.writeQuery({
          query: stateQuery,
          data: { ...initialStateData, stepList: STEPS, activeStep: STEPS[3] },
        });
        createComponent({ apolloProvider: mockApolloProvider });
        return waitForPromises();
      });

      it('redirects to the location if it succeeds', async () => {
        Api.confirmOrder = jest.fn().mockResolvedValueOnce({ data: { location } });
        findConfirmButton().vm.$emit('click');
        await waitForPromises();

        expect(UrlUtility.redirectTo).toHaveBeenCalledTimes(1); // eslint-disable-line import/no-deprecated
        expect(UrlUtility.redirectTo).toHaveBeenCalledWith(location); // eslint-disable-line import/no-deprecated
      });

      describe('when there is a failure', () => {
        const errors = 'an error';
        const expectedError = new Error(JSON.stringify(errors));

        beforeEach(() => {
          Api.confirmOrder = jest.fn().mockResolvedValueOnce({ data: { errors } });
          findConfirmButton().vm.$emit('click');

          return waitForPromises();
        });

        it('emits an error', () => {
          expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[expectedError]]);
        });
      });
    });

    describe('when failing to receive step data', () => {
      beforeEach(async () => {
        mockApolloProvider = createMockApolloProvider([]);
        createComponent({ apolloProvider: mockApolloProvider });
        await waitForPromises();
        mockApolloProvider.clients.defaultClient.clearStore();
      });

      afterEach(() => {
        createAlert.mockClear();
      });

      it('does not render the root element', () => {
        expect(findRootElement().exists()).toBe(false);
      });
    });
  });

  describe('when inactive', () => {
    it('does not show buttons', async () => {
      mockApolloProvider = createMockApolloProvider(STEPS, 1);
      createComponent({ apolloProvider: mockApolloProvider });
      await waitForPromises();

      expect(findConfirmButton().exists()).toBe(false);
    });
  });
});
