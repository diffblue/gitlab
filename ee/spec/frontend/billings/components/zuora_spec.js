import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Zuora from 'ee/billings/components/zuora.vue';

describe('Zuora', () => {
  let wrapper;

  const createComponent = (data = {}) => {
    wrapper = shallowMount(Zuora, {
      propsData: {
        iframeUrl: 'https://gitlab.com',
        allowedOrigin: 'https://gitlab.com',
        initialHeight: 300,
      },
      data() {
        return data;
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);

  let addEventListenerSpy;
  let postMessageSpy;
  let removeEventListenerSpy;

  afterEach(() => {
    wrapper.destroy();
  });

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
      wrapper.vm.handleFrameLoaded();
    });

    it('is not in the loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('adds an event listener', () => {
      expect(addEventListenerSpy).toHaveBeenCalledWith(
        'message',
        wrapper.vm.handleFrameMessages,
        true,
      );
    });
  });

  describe('on submit', () => {
    beforeEach(() => {
      createComponent({
        error: 'an error occurred',
        isLoading: false,
        iframeHeight: 400,
      });
      wrapper.vm.$refs.zuora = { contentWindow: { postMessage: jest.fn() } };
      postMessageSpy = jest.spyOn(wrapper.vm.$refs.zuora.contentWindow, 'postMessage');
      wrapper.vm.submit();
    });

    it('hides the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('is in the loading state', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('resets the height to the initial height', () => {
      expect(wrapper.vm.iframeHeight).toBe(300);
    });

    it('posts the submit message to the iframe', () => {
      expect(postMessageSpy).toHaveBeenCalledWith('submit', 'https://gitlab.com');
    });
  });

  describe('when showing an alert', () => {
    beforeEach(() => {
      createComponent({ error: 'an error occurred' });
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
    });

    describe('when success', () => {
      beforeEach(() => {
        wrapper.vm.handleFrameMessages({ origin: 'https://gitlab.com', data: { success: true } });
      });

      it('emits the success event', () => {
        expect(wrapper.emitted('success')).toBeDefined();
      });
    });

    describe('when not from an allowed origin', () => {
      beforeEach(() => {
        wrapper.vm.handleFrameMessages({ origin: 'https://test.com', data: { success: true } });
      });

      it('emits no event', () => {
        expect(wrapper.emitted()).toEqual({});
      });
    });

    describe('when failure and code less than 7', () => {
      beforeEach(() => {
        wrapper.vm.handleFrameMessages({
          origin: 'https://gitlab.com',
          data: { success: false, code: 6 },
        });
      });

      it('emits no event', () => {
        expect(wrapper.emitted()).toEqual({});
      });

      it('increases the iframe height', () => {
        expect(wrapper.vm.iframeHeight).toBe(315);
      });
    });

    describe('when failure and code greater than 6', () => {
      beforeEach(() => {
        removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
        wrapper.vm.handleFrameMessages({
          origin: 'https://gitlab.com',
          data: { success: false, code: 7, msg: 'error' },
        });
      });

      it('emits the failure event with the error message', () => {
        expect(wrapper.emitted('failure')[0]).toEqual([{ msg: 'error' }]);
      });

      it('removes the message event listener', () => {
        expect(removeEventListenerSpy).toHaveBeenCalledWith(
          'message',
          wrapper.vm.handleFrameMessages,
          true,
        );
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
      expect(removeEventListenerSpy).toHaveBeenCalledWith(
        'message',
        wrapper.vm.handleFrameMessages,
        true,
      );
    });
  });
});
