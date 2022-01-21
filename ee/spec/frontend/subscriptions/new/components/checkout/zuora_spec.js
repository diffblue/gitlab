import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import Component from 'ee/subscriptions/new/components/checkout/zuora.vue';
import { getStoreConfig } from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';

describe('Zuora', () => {
  Vue.use(Vuex);

  let store;
  let wrapper;

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
    wrapper.destroy();
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

  describe('renderZuoraIframe', () => {
    it('is called when the paymentFormParams are updated', () => {
      createComponent();

      expect(actionMocks.zuoraIframeRendered).not.toHaveBeenCalled();

      store.commit(types.UPDATE_PAYMENT_FORM_PARAMS, {});

      return nextTick().then(() => {
        expect(actionMocks.zuoraIframeRendered).toHaveBeenCalled();
      });
    });
  });
});
