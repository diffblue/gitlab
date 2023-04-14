import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import Component from 'ee/subscriptions/new/components/checkout/zuora.vue';
import { getStoreConfig } from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import { mockTracking } from 'helpers/tracking_helper';

describe('Zuora', () => {
  Vue.use(Vuex);

  let store;
  let wrapper;
  let trackingSpy;

  const actionMocks = {
    startLoadingZuoraScript: jest.fn(),
    fetchPaymentFormParams: jest.fn(),
    zuoraIframeRendered: jest.fn(),
    paymentFormSubmitted: jest.fn(),
  };

  const createComponent = (props = {}) => {
    const { actions, ...storeConfig } = getStoreConfig();
    store = new Vuex.Store({
      ...storeConfig,
      actions: {
        ...actions,
        ...actionMocks,
      },
    });

    wrapper = shallowMount(Component, {
      propsData: {
        active: true,
        ...props,
      },
      store,
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
      render() {},
    };
  });

  afterEach(() => {
    delete window.Z;
  });

  describe('mounted', () => {
    it('starts loading zuora script', () => {
      createComponent();

      expect(actionMocks.startLoadingZuoraScript).toHaveBeenCalled();
    });
  });

  describe('when active', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show the loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('the zuora_payment selector should be visible', () => {
      expect(findZuoraPayment().element.style.display).toEqual('');
    });

    describe('when toggling the loading indicator', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, true);

        return nextTick();
      });

      it('shows the loading icon', () => {
        expect(findLoading().exists()).toBe(true);
      });

      it('the zuora_payment selector should not be visible', () => {
        expect(findZuoraPayment().element.style.display).toEqual('none');
      });
    });
  });

  describe('when not active', () => {
    beforeEach(() => {
      createComponent({ active: false });
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('the zuora_payment selector should not be visible', () => {
      expect(findZuoraPayment().element.style.display).toEqual('none');
    });
  });

  describe('when rendering', () => {
    beforeEach(() => {
      createComponent();
      store.commit(types.UPDATE_PAYMENT_FORM_PARAMS, {});
      return nextTick();
    });

    it('renderZuoraIframe is called when the paymentFormParams are updated', () => {
      expect(actionMocks.zuoraIframeRendered).toHaveBeenCalled();
      wrapper.vm.handleZuoraCallback();
      expect(actionMocks.paymentFormSubmitted).toHaveBeenCalled();
    });

    it('tracks frame_loaded event', () => {
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'iframe_loaded', {
        category: 'Zuora_cc',
      });
    });
  });

  describe('tracking', () => {
    it('emits success event on correct response', async () => {
      wrapper.vm.handleZuoraCallback({ success: 'true' });
      await nextTick();
      expect(wrapper.emitted().success.length).toEqual(1);
    });

    describe('with an error response', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.handleZuoraCallback({ errorMessage: '1337' });
        return nextTick();
      });

      it('emits error with message', () => {
        expect(wrapper.emitted().error.length).toEqual(1);
        expect(wrapper.emitted().error[0]).toEqual(['1337']);
      });

      it('tracks Zuora error', () => {
        expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
          label: 'payment_form_submitted',
          property: '1337',
          category: 'Zuora_cc',
        });
      });
    });
  });
});
