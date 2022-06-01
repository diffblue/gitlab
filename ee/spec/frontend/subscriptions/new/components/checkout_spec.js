import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import Component from 'ee/subscriptions/new/components/checkout.vue';
import createStore from 'ee/subscriptions/new/store';
import { mockTracking } from 'helpers/tracking_helper';

describe('Checkout', () => {
  Vue.use(Vuex);

  describe('tracking', () => {
    it('tracks render on mount', () => {
      const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      const wrapper = shallowMount(Component, { store: createStore() });

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
        label: 'saas_checkout',
      });

      wrapper.destroy();
    });
  });
});
