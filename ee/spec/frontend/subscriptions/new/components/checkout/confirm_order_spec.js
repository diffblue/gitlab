import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import Api from 'ee/api';
import { STEPS } from 'ee/subscriptions/constants';
import ConfirmOrder from 'ee/subscriptions/new/components/checkout/confirm_order.vue';
import createStore from 'ee/subscriptions/new/store';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';

jest.mock('~/flash');

describe('Confirm Order', () => {
  Vue.use(Vuex);
  Vue.use(VueApollo);

  let wrapper;

  jest.mock('ee/api.js');

  const store = createStore();

  function createComponent(options = {}) {
    return shallowMount(ConfirmOrder, {
      store,
      ...options,
    });
  }

  const findConfirmButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Active', () => {
    describe('when receiving proper step data', () => {
      beforeEach(async () => {
        const mockApolloProvider = createMockApolloProvider(STEPS, 3);
        wrapper = createComponent({ apolloProvider: mockApolloProvider });
      });

      it('button should be visible', () => {
        expect(findConfirmButton().exists()).toBe(true);
      });

      it('shows the text "Confirm purchase"', () => {
        expect(findConfirmButton().text()).toBe('Confirm purchase');
      });

      it('the loading indicator should not be visible', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    describe('Clicking the button', () => {
      beforeEach(() => {
        const mockApolloProvider = createMockApolloProvider(STEPS, 3);
        wrapper = createComponent({ apolloProvider: mockApolloProvider });
        Api.confirmOrder = jest.fn().mockReturnValue(new Promise(jest.fn()));

        findConfirmButton().vm.$emit('click');
      });

      it('calls the confirmOrder API method', () => {
        expect(Api.confirmOrder).toHaveBeenCalled();
      });

      it('shows the text "Confirming..."', () => {
        expect(findConfirmButton().text()).toBe('Confirming...');
      });

      it('the loading indicator should be visible', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });
    });
  });

  describe('Inactive', () => {
    beforeEach(async () => {
      const mockApolloProvider = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApolloProvider });
    });

    it('button should not be visible', () => {
      expect(findConfirmButton().exists()).toBe(false);
    });
  });
});
