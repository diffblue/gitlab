import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Api from 'ee/api';
import { ERROR_LOADING_PAYMENT_FORM, STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Zuora from 'ee/vue_shared/purchase_flow/components/checkout/zuora.vue';
import { stateData as initialStateData } from 'ee_jest/subscriptions/mock_data';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking } from 'helpers/tracking_helper';
import { HTTP_STATUS_OK, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

Vue.use(VueApollo);

describe('Zuora', () => {
  let axiosMock;
  let wrapper;
  let trackingSpy;

  const fakePaymentMethodId = '000000000';

  const createComponent = (props = {}, data = {}, apolloLocalState = {}, resolvers = {}) => {
    const apolloProvider = createMockApolloProvider(STEPS, STEPS[1], resolvers);
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data: merge({}, initialStateData, apolloLocalState),
    });

    wrapper = shallowMount(Zuora, {
      apolloProvider,
      propsData: {
        active: true,
        ...props,
      },
      data() {
        return { ...data };
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const findLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findZuoraPayment = () => wrapper.find('#zuora_payment');

  beforeEach(() => {
    window.Z = {
      runAfterRender(fn) {
        return Promise.resolve().then(fn);
      },
      render: jest.fn(),
    };

    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(Api.paymentFormPath).reply(HTTP_STATUS_OK, {});
    axiosMock.onGet(Api.paymentMethodPath).reply(HTTP_STATUS_OK, { id: fakePaymentMethodId });
  });

  afterEach(() => {
    delete window.Z;
  });

  describe('when active', () => {
    beforeEach(() => {
      createComponent({}, { isLoading: false });
    });

    it('shows the loading icon', () => {
      expect(findLoading().exists()).toBe(true);
    });

    it('the zuora_payment selector should be hidden', () => {
      expect(findZuoraPayment().isVisible()).toBe(false);
    });

    describe('when toggling the loading indicator', () => {
      beforeEach(() => {
        createComponent({}, { isLoading: true });
      });

      it('shows the loading icon', () => {
        expect(findLoading().exists()).toBe(true);
      });

      it('the zuora_payment selector should not be visible', () => {
        expect(findZuoraPayment().isVisible()).toBe(false);
      });
    });
  });

  describe('when not active', () => {
    beforeEach(() => {
      createComponent({ active: false });
    });

    it('the zuora_payment selector should not be visible', () => {
      expect(findZuoraPayment().isVisible()).toBe(false);
    });
  });

  describe('when fetch payment params is successful', () => {
    beforeEach(() => {
      createComponent();
      wrapper.vm.zuoraScriptEl.onload();
      return waitForPromises();
    });

    it('tracks frame_loaded event', () => {
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'iframe_loaded', {
        category: 'Zuora_cc',
      });
    });
  });

  describe('when fetch payment params is not successful', () => {
    beforeEach(() => {
      createComponent({}, { isLoading: false });
      wrapper.vm.zuoraScriptEl.onload();
      axiosMock.onGet(Api.paymentFormPath).reply(HTTP_STATUS_UNAUTHORIZED, {});
      return waitForPromises();
    });

    it('tracks the error event', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
        label: 'payment_form_fetch_params',
        property: 'Request failed with status code 401',
        category: 'Zuora_cc',
      });
    });

    it('emits an `error` event', () => {
      expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([
        [new Error(ERROR_LOADING_PAYMENT_FORM)],
      ]);
    });
  });

  describe('when fetch payment details is successful', () => {
    beforeEach(() => {
      window.Z = {
        runAfterRender(fn) {
          return Promise.resolve().then(fn);
        },
        render(params, object, fn) {
          return Promise.resolve().then(fn);
        },
      };

      createComponent({}, { isLoading: false });
      wrapper.vm.zuoraScriptEl.onload();
      return waitForPromises();
    });

    it('tracks success event', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(2);
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'success', { category: 'Zuora_cc' });
    });
  });

  describe('when fetch payment details is not successful', () => {
    const error = new Error('Request failed with status code 401');

    beforeEach(() => {
      window.Z = {
        runAfterRender(fn) {
          return Promise.resolve().then(fn);
        },
        render(params, object, fn) {
          return Promise.resolve().then(fn);
        },
      };

      createComponent({}, { isLoading: false });
      wrapper.vm.zuoraScriptEl.onload();
      axiosMock.onGet(Api.paymentMethodPath).reply(HTTP_STATUS_UNAUTHORIZED, {});
      return waitForPromises();
    });

    it('tracks the error event', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(2);
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
        label: 'payment_form_submitted',
        property: error.message,
        category: 'Zuora_cc',
      });
    });

    it('emits an `error` event', () => {
      expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
    });
  });

  describe('when updateState is not successful', () => {
    const error = new Error('updateState failed');
    const updateState = jest.fn().mockRejectedValue(error);
    const activateNextStep = jest.fn();

    beforeEach(() => {
      window.Z = {
        runAfterRender(fn) {
          return Promise.resolve().then(fn);
        },
        render(params, object, fn) {
          return Promise.resolve().then(fn);
        },
      };

      createComponent(
        {},
        { isLoading: false },
        {},
        { Mutation: { activateNextStep, updateState } },
      );
      wrapper.vm.zuoraScriptEl.onload();
      return waitForPromises();
    });

    it('tracks the error event', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(2);
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
        label: 'payment_form_submitted',
        property: error.message,
        category: 'Zuora_cc',
      });
    });

    it('invokes updateState mutation', () => {
      expect(updateState).toHaveBeenNthCalledWith(
        1,
        expect.any(Object),
        { input: { paymentMethod: { id: fakePaymentMethodId } } },
        expect.any(Object),
        expect.any(Object),
      );
    });

    it('does not activate next step', () => {
      expect(activateNextStep).not.toHaveBeenCalled();
    });

    it('emits an `error` event', () => {
      expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
    });
  });

  describe('when activateNextStep is not successful', () => {
    const error = new Error('activateNextStep failed');
    const updateState = jest.fn().mockResolvedValue('');
    const activateNextStep = jest.fn().mockRejectedValue(error);

    beforeEach(() => {
      window.Z = {
        runAfterRender(fn) {
          return Promise.resolve().then(fn);
        },
        render(params, object, fn) {
          return Promise.resolve().then(fn);
        },
      };

      createComponent(
        {},
        { isLoading: false },
        {},
        { Mutation: { activateNextStep, updateState } },
      );
      wrapper.vm.zuoraScriptEl.onload();
      return waitForPromises();
    });

    it('tracks the error event', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(3);
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
        label: 'payment_form_submitted',
        property: error.message,
        category: 'Zuora_cc',
      });
    });

    it('updates the state', () => {
      expect(updateState).toHaveBeenNthCalledWith(
        1,
        expect.any(Object),
        { input: { paymentMethod: { id: fakePaymentMethodId } } },
        expect.any(Object),
        expect.any(Object),
      );
    });

    it('does not activate next step', () => {
      expect(activateNextStep).toHaveBeenCalled();
    });

    it('emits an `error` event', () => {
      expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
    });
  });

  describe.each(['', '111111'])('when rendering the iframe with account id: %s', (id) => {
    beforeEach(() => {
      createComponent({ accountId: id }, { isLoading: false });
      wrapper.vm.zuoraScriptEl.onload();
      return waitForPromises();
    });

    it(`calls render with ${id}`, () => {
      expect(window.Z.render).toHaveBeenCalledWith(
        {
          field_accountId: id,
          retainValues: 'true',
          style: 'inline',
          submitEnabled: 'true',
        },
        {},
        expect.any(Function),
      );
    });
  });
});
