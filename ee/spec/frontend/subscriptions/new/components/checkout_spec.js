import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ProgressBar from 'ee/registrations/components/progress_bar.vue';
import Component from 'ee/subscriptions/new/components/checkout.vue';
import createStore from 'ee/subscriptions/new/store';
import { mockTracking } from 'helpers/tracking_helper';

describe('Checkout', () => {
  Vue.use(Vuex);

  let store;
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(Component, {
      store,
    });
  };

  const findProgressBar = () => wrapper.findComponent(ProgressBar);

  beforeEach(() => {
    store = createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([
    [true, true],
    [false, false],
  ])('when isNewUser=%s', (isNewUser, visible) => {
    beforeEach(() => {
      store.state.isNewUser = isNewUser;
    });

    it(`progress bar visibility is ${visible}`, () => {
      expect(findProgressBar().exists()).toBe(visible);
    });
  });

  describe('passing the correct options to the progress bar component', () => {
    beforeEach(() => {
      store.state.isNewUser = true;
    });

    it('passes the steps', () => {
      expect(findProgressBar().props('steps')).toEqual([
        'Your profile',
        'Checkout',
        'Your GitLab group',
      ]);
    });

    it('passes the current step', () => {
      expect(findProgressBar().props('currentStep')).toEqual('Checkout');
    });
  });

  describe('tracking', () => {
    it('tracks render on mount', () => {
      const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

      shallowMount(Component, { store: createStore() });

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
        label: 'saas_checkout',
      });
    });
  });
});
