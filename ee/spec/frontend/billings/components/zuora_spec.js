import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Zuora from 'ee/billings/components/zuora.vue';
import { mockTracking } from 'helpers/tracking_helper';

describe('Zuora', () => {
  let wrapper;
  let addEventListenerSpy;
  let removeEventListenerSpy;
  let trackingSpy;

  const createComponent = () => {
    wrapper = shallowMount(Zuora, {
      propsData: {
        iframeUrl: 'https://gitlab.com',
        allowedOrigin: 'https://gitlab.com',
        initialHeight: 300,
      },
      attachTo: document.body,
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findIFrame = () => wrapper.find('iframe');

  describe('on creation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is in the loading state', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when iframe loaded', () => {
    beforeEach(() => {
      addEventListenerSpy = jest.spyOn(window, 'addEventListener');
      createComponent();
      findIFrame().trigger('load');
    });

    it('is not in the loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('adds an event listener', () => {
      expect(addEventListenerSpy).toHaveBeenCalled();
    });

    it('tracks frame_loaded event', () => {
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'iframe_loaded', {
        category: 'Zuora_cc',
      });
    });
  });

  describe('when showing an alert', () => {
    beforeEach(() => {
      createComponent();
      findIFrame().trigger('load');

      wrapper.trigger('message', {
        origin: 'https://gitlab.com',
        data: { success: false, code: 7, msg: 'an error occurred' },
      });
    });

    it('shows the alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe('an error occurred');
    });

    describe('when dismissing the alert', () => {
      beforeEach(() => {
        findAlert().vm.$emit('dismiss');
      });

      it('hides the alert', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });
  });

  describe('handling iframe messages', () => {
    beforeEach(() => {
      createComponent();
      findIFrame().trigger('load');
    });

    describe('when success', () => {
      beforeEach(() => {
        wrapper.trigger('message', { origin: 'https://gitlab.com', data: { success: true } });
      });

      it('emits the success event', () => {
        expect(wrapper.emitted('success')).toBeDefined();
      });

      it('tracks success event', () => {
        expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'success', { category: 'Zuora_cc' });
      });
    });

    describe('when not from an allowed origin', () => {
      beforeEach(() => {
        wrapper.trigger('message', { origin: 'https://test.com', data: { success: true } });
      });

      it('emits only loading event', () => {
        expect(Object.keys(wrapper.emitted())).toHaveLength(1);
        expect(wrapper.emitted('loading')).toHaveLength(1);
      });
    });

    describe('when failure and code less than 7', () => {
      const msg = 'a propagated error';

      beforeEach(() => {
        wrapper.trigger('message', {
          origin: 'https://gitlab.com',
          data: { success: false, code: 6, msg },
        });
      });

      it('emits only loading event with value `false`', () => {
        expect(Object.keys(wrapper.emitted())).toHaveLength(1);
        expect(wrapper.emitted('loading')).toHaveLength(1);
        expect(wrapper.emitted('loading')[0]).toEqual([false]);
      });

      it('increases the iframe height', () => {
        expect(findIFrame().element.height).toBe('315');
      });

      it('tracks client side Zuora error', () => {
        expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'client_error', {
          property: msg,
          category: 'Zuora_cc',
        });
      });
    });

    describe('when failure and code greater than 6', () => {
      beforeEach(() => {
        removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
        wrapper.trigger('message', {
          origin: 'https://gitlab.com',
          data: { success: false, code: 7, msg: 'error' },
        });
      });

      it('emits the failure event with the error message', () => {
        expect(wrapper.emitted('failure')[0]).toEqual([{ msg: 'error' }]);
      });

      it('emits loading event with value `false`', () => {
        expect(wrapper.emitted('loading')).toHaveLength(1);
        expect(wrapper.emitted('loading')[0]).toEqual([false]);
      });

      it('removes the message event listener', () => {
        expect(removeEventListenerSpy).toHaveBeenCalled();
      });

      it('tracks Zuora error', () => {
        expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
          property: 'error',
          category: 'Zuora_cc',
        });
      });
    });
  });

  describe('on destroying', () => {
    beforeEach(() => {
      createComponent();
      removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
      wrapper.destroy();
    });

    it('removes the message event listener', () => {
      expect(removeEventListenerSpy).toHaveBeenCalled();
    });
  });
});
