import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Zuora, {
  Action,
  DEFAULT_IFRAME_BOTTOM_HEIGHT,
  DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT,
  ERROR,
  ERROR_CLIENT,
  Event,
  SUCCESS,
  ZUORA_EVENT_CATEGORY,
} from 'ee/billings/components/zuora_simple.vue';
import { ERROR_LOADING_PAYMENT_FORM } from 'ee/subscriptions/constants';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Api from 'ee/api';

Vue.use(VueApollo);

jest.mock('ee/api');

describe('Zuora', () => {
  let trackingSpy;
  let wrapper;

  const currentUserId = 111;
  const initialHeight = 300;
  const paymentFormId = 'payment-form-id';
  const refId = '123412341234';

  const createComponent = (props = {}, data = {}) => {
    wrapper = shallowMount(Zuora, {
      propsData: {
        currentUserId,
        initialHeight,
        paymentFormId,
        ...props,
      },
      data() {
        return { ...data };
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findZuoraPayment = () => wrapper.find('#zuora_payment');

  beforeEach(() => {
    window.Z = {
      runAfterRender: (fn) => fn(),
      renderWithErrorHandler: jest.fn(),
    };

    jest
      .spyOn(Api, 'fetchPaymentFormParams')
      .mockResolvedValue({ data: { someData: 'some-data' } });
  });

  afterEach(() => {
    delete window.Z;
    unmockTracking();
    wrapper.destroy();
  });

  describe('initial state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the loading icon', () => {
      expect(findLoading().exists()).toBe(true);
    });

    it('does not show an error alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not show zuora_payment', () => {
      expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(true);
    });

    it('applies the default height', () => {
      expect(findZuoraPayment().attributes('style')).toBe(
        `height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
      );
    });
  });

  describe('when the scripts load', () => {
    beforeEach(() => {
      jest.spyOn(Api, 'fetchPaymentFormParams').mockResolvedValue({});
      createComponent();
      wrapper.vm.zuoraScriptEl.onload();
    });

    it('calls validatePaymentMethod with the correct params', () => {
      expect(Api.fetchPaymentFormParams).toHaveBeenCalledTimes(1);
      expect(Api.fetchPaymentFormParams).toHaveBeenCalledWith(paymentFormId);
    });
  });

  describe('iFrame callbacks', () => {
    describe('paymentFormSubmitted', () => {
      describe('when not successful', () => {
        beforeEach(() => {
          window.Z = {
            runAfterRender: (fn) => fn(),
            renderWithErrorHandler: (params, _, paymentFormSubmitted) =>
              Promise.resolve().then(() =>
                paymentFormSubmitted({ success: 'false', message: ERROR }),
              ),
          };
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('does not show the loading icon', () => {
          expect(findLoading().exists()).toBe(false);
        });

        it('shows zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(false);
        });

        it('applies the correct style', () => {
          const height = initialHeight - DEFAULT_IFRAME_BOTTOM_HEIGHT;

          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${height}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(ERROR);
        });

        it('tracks the y error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.PAYMENT_SUBMITTED,
            property: ERROR,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('when successful', () => {
        beforeEach(() => {
          window.Z = {
            runAfterRender: (fn) => fn(),
            renderWithErrorHandler: (params, _, paymentFormSubmitted) =>
              Promise.resolve().then(() => paymentFormSubmitted({ success: true, refId })),
          };

          jest.spyOn(Api, 'validatePaymentMethod').mockResolvedValue({});

          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('calls validatePaymentMethod with the correct params', () => {
          expect(Api.validatePaymentMethod).toHaveBeenCalledTimes(1);
          expect(Api.validatePaymentMethod).toHaveBeenCalledWith(refId, currentUserId);
        });
      });
    });

    describe('handleError', () => {
      describe('with an error from the iFrame', () => {
        const iFrameErrorMessage = 'iFrame error';

        beforeEach(() => {
          window.Z = {
            runAfterRender: (fn) => fn(),
            renderWithErrorHandler: (params, _, paymentFormSubmitted, handleError) =>
              Promise.resolve().then(() => handleError(ERROR, null, iFrameErrorMessage)),
          };
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(iFrameErrorMessage);
        });

        it('tracks the payment_form_submitted error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.PAYMENT_SUBMITTED,
            property: iFrameErrorMessage,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });
    });

    describe('handleMessage', () => {
      beforeEach(() => {
        window.Z = {
          runAfterRender: (fn) => fn(),
          sendErrorMessageToHpm: jest.fn(),
        };

        jest.spyOn(Api, 'fetchPaymentFormParams').mockResolvedValue(new Promise(() => {}));
        jest.spyOn(Api, 'validatePaymentMethod').mockResolvedValue(new Promise(() => {}));
        createComponent();
      });

      describe('when dispatching an unrelated event', () => {
        it('shows the loading icon', () => {
          window.dispatchEvent(new MessageEvent('message'));

          expect(findLoading().exists()).toBe(true);
        });
      });

      describe('when dispatching an empty event', () => {
        it('it shows the loading icon', () => {
          window.dispatchEvent(new MessageEvent('message', { data: '' }));

          expect(findLoading().exists()).toBe(true);
        });
      });

      describe('when dispatching an event with the wrong format', () => {
        it('it shows the loading icon', () => {
          window.dispatchEvent(new MessageEvent('message', { data: [] }));

          expect(findLoading().exists()).toBe(true);
        });
      });

      describe(`when dispatching a ${Action.CUSTOMIZE_ERROR_MESSAGE} event type`, () => {
        const key = 'CreditCardNumber';
        const message = 'Required field';
        const data = JSON.stringify({
          action: Action.CUSTOMIZE_ERROR_MESSAGE,
          key,
          message,
        });

        beforeEach(() => {
          window.dispatchEvent(new MessageEvent('message', { data }));
        });

        it('does not show the loading icon', () => {
          expect(findLoading().exists()).toBe(false);
        });

        it('does not show an error alert', () => {
          expect(findAlert().exists()).toBe(false);
        });

        it('applies the default style', async () => {
          jest
            .spyOn(Api, 'fetchPaymentFormParams')
            .mockResolvedValue({ data: { someData: 'some-data' } });
          await wrapper.vm.zuoraScriptEl.onload();

          const height = initialHeight - DEFAULT_IFRAME_BOTTOM_HEIGHT;

          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${height}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('invokes sendErrorMessageToHpm with the correct params', () => {
          expect(window.Z.sendErrorMessageToHpm).toHaveBeenCalledTimes(1);
          expect(window.Z.sendErrorMessageToHpm).toHaveBeenCalledWith(key, message);
        });

        it('tracks client_error event', () => {
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, ERROR_CLIENT, {
            category: ZUORA_EVENT_CATEGORY,
            label: Event.PAYMENT_SUBMITTED,
            property: message,
          });
        });
      });

      describe(`when dispatching a ${Action.RESIZE} event type`, () => {
        const receivedHeight = 500;
        const height = receivedHeight - DEFAULT_IFRAME_BOTTOM_HEIGHT;
        const data = JSON.stringify({ action: Action.RESIZE, height: receivedHeight });

        beforeEach(() => {
          window.dispatchEvent(new MessageEvent('message', { data }));
        });

        it('does not show the loading icon', () => {
          expect(findLoading().exists()).toBe(false);
        });

        it('applies the style with the calculated height', async () => {
          jest
            .spyOn(Api, 'fetchPaymentFormParams')
            .mockResolvedValue({ data: { someData: 'some-data' } });
          await wrapper.vm.zuoraScriptEl.onload();

          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${height}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );

          window.dispatchEvent(
            new MessageEvent('message', {
              data: JSON.stringify({ action: Action.RESIZE, height: 0 }),
            }),
          );

          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${height}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });
      });
    });
  });

  describe('API requests', () => {
    describe('fetchPaymentFormParams', () => {
      describe('when pending', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'fetchPaymentFormParams').mockResolvedValue(new Promise(() => {}));
          createComponent();
        });

        it('shows the loading icon', () => {
          wrapper.vm.zuoraScriptEl.onload();

          expect(findLoading().exists()).toBe(true);
        });

        it('shows zuora_payment', () => {
          wrapper.vm.zuoraScriptEl.onload();

          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(true);
        });
      });

      describe('when successfully resolved', () => {
        beforeEach(() => {
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('does not show the loading icon', () => {
          expect(findLoading().exists()).toBe(false);
        });

        it('shows zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(false);
        });

        it('applies the correct style', () => {
          const height = initialHeight - DEFAULT_IFRAME_BOTTOM_HEIGHT;

          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${height}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('tracks frame_loaded event', () => {
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, Event.IFRAME_LOADED, {
            category: ZUORA_EVENT_CATEGORY,
          });
        });

        it('calls the Z method with the correct params', () => {
          expect(window.Z.renderWithErrorHandler).toHaveBeenCalledTimes(1);
          expect(window.Z.renderWithErrorHandler).toHaveBeenCalledWith(
            expect.objectContaining({
              location: btoa(window.location.href),
              user_id: currentUserId,
              someData: 'some-data',
            }),
            expect.anything(),
            expect.any(Function),
            expect.any(Function),
          );
        });
      });

      describe('when resolved with an error', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'fetchPaymentFormParams').mockResolvedValue({ data: { errors: ERROR } });
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(ERROR_LOADING_PAYMENT_FORM);
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(1);
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.FETCH_PARAMS,
            property: ERROR,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('when resolved with empty data', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'fetchPaymentFormParams').mockResolvedValue({ data: {} });
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(ERROR_LOADING_PAYMENT_FORM);
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(1);
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.FETCH_PARAMS,
            property: ERROR_LOADING_PAYMENT_FORM,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('when not resolved', () => {
        beforeEach(() => {
          jest
            .spyOn(Api, 'fetchPaymentFormParams')
            .mockRejectedValue(new Error('Request failed with status code 401'));
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('does not show the loading icon', () => {
          expect(findLoading().exists()).toBe(false);
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(ERROR_LOADING_PAYMENT_FORM);
        });

        it('does not show zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(true);
        });

        it('applies the default height', () => {
          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(1);
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.FETCH_PARAMS,
            property: 'Request failed with status code 401',
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });
    });

    describe('validatePaymentMethod', () => {
      beforeEach(() => {
        window.Z = {
          runAfterRender: (fn) => fn(),
          renderWithErrorHandler: (params, _, paymentFormSubmitted) =>
            paymentFormSubmitted({ success: true, refId }),
        };
      });

      describe('when pending', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'validatePaymentMethod').mockResolvedValue(new Promise(() => {}));

          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows the loading icon', () => {
          expect(findLoading().exists()).toBe(true);
        });

        it('shows zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(true);
        });
      });

      describe('when successfully resolved', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'validatePaymentMethod').mockResolvedValue({ data: { success: 'true' } });

          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('applies the correct style', () => {
          const height = initialHeight - DEFAULT_IFRAME_BOTTOM_HEIGHT;

          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${height}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('does not show an error alert', () => {
          expect(findAlert().exists()).toBe(false);
        });

        it('emits a success event', () => {
          expect(wrapper.emitted(SUCCESS)).toHaveLength(1);
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, SUCCESS, {
            label: Event.PAYMENT_VALIDATE,
            property: `payment_method_id: ${refId}`,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('when resolved with an error', () => {
        beforeEach(() => {
          jest
            .spyOn(Api, 'validatePaymentMethod')
            .mockResolvedValue({ data: { success: 'false' } });
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(wrapper.vm.$options.i18n.paymentValidationError);
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.PAYMENT_VALIDATE,
            property: wrapper.vm.$options.i18n.paymentValidationError,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('when resolved with empty data', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'validatePaymentMethod').mockResolvedValue({ data: {} });
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(wrapper.vm.$options.i18n.paymentValidationError);
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.PAYMENT_VALIDATE,
            property: wrapper.vm.$options.i18n.paymentValidationError,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('when not resolved', () => {
        beforeEach(() => {
          jest
            .spyOn(Api, 'validatePaymentMethod')
            .mockRejectedValue(new Error('Request failed with status code 401'));
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('does not show the loading icon', () => {
          expect(findLoading().exists()).toBe(false);
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe('Request failed with status code 401');
        });

        it('does not show zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(false);
        });

        it('applies the correct style', () => {
          const height = initialHeight - DEFAULT_IFRAME_BOTTOM_HEIGHT;

          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${height}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, ERROR, {
            label: Event.PAYMENT_VALIDATE,
            property: 'Request failed with status code 401',
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });
    });
  });
});
