import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Zuora, {
  Action,
  DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT,
  Event,
  TrackingEvent,
  TrackingLabel,
  ZUORA_EVENT_CATEGORY,
  INVALID_SECURITY,
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
    wrapper = shallowMountExtended(Zuora, {
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
  const findLoadingContainer = () => wrapper.findByTestId('loading-container');
  const findZuoraPayment = () => wrapper.find('#zuora_payment');

  const expectLoadingDoesNotExist = () => {
    expect(wrapper.emitted(Event.LOADING)).toEqual([[false]]);
    expect(findLoadingContainer().exists()).toBe(false);
    expect(findLoading().exists()).toBe(false);
  };

  const expectLoadingExists = () => {
    expect(findLoadingContainer().attributes('style')).toBe(
      `height: ${initialHeight}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
    );
    expect(findLoading().exists()).toBe(true);
  };

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
  });

  describe('initial state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the loading icon', () => {
      expectLoadingExists();
    });

    it('does not show an error alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not show zuora_payment', () => {
      expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(true);
    });

    it('applies the default height', () => {
      expect(findZuoraPayment().attributes('style')).toBe(`height: 0px;`);
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

  describe('when the script fails to load', () => {
    beforeEach(() => {
      createComponent();
      wrapper.vm.zuoraScriptEl.onerror();
    });

    it('emits load-error', () => {
      expect(wrapper.emitted(Event.LOAD_ERROR)).toHaveLength(1);
    });

    it('tracks the iframe load error', () => {
      expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
        label: TrackingLabel.ZUORA_SCRIPT_LOAD_ERROR,
        property: ERROR_LOADING_PAYMENT_FORM,
        category: ZUORA_EVENT_CATEGORY,
      });
    });

    it('shows an error alert', () => {
      expect(findAlert().text()).toBe(ERROR_LOADING_PAYMENT_FORM);
    });
  });

  describe('iFrame callbacks', () => {
    describe('paymentFormSubmitted', () => {
      describe('when not successful', () => {
        const errorCode = 'PAYMENT_ERROR';
        const errorMessage = 'Payment Error';

        beforeEach(() => {
          window.Z = {
            runAfterRender: (fn) => fn(),
            renderWithErrorHandler: (params, _, paymentFormSubmitted) =>
              Promise.resolve().then(() =>
                paymentFormSubmitted({ success: 'false', errorCode, errorMessage }),
              ),
          };
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('does not show the loading icon', () => {
          expectLoadingDoesNotExist();
        });

        it('shows zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(false);
        });

        it('applies the correct style', () => {
          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${initialHeight}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(errorMessage);
        });

        it('emits payment-submit-error', () => {
          expect(wrapper.emitted(Event.PAYMENT_SUBMIT_ERROR)).toEqual([
            [{ errorCode, errorMessage }],
          ]);
        });

        it('tracks the y error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.PAYMENT_SUBMITTED,
            property: errorMessage,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('when not successful with invalid security code', () => {
        const errorMessage = 'Iframe error';

        beforeEach(() => {
          window.Z = {
            runAfterRender: (fn) => fn(),
            renderWithErrorHandler: (params, _, paymentFormSubmitted) =>
              paymentFormSubmitted({
                success: false,
                refId,
                errorCode: INVALID_SECURITY,
                errorMessage,
              }),
          };
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('emits load-error', () => {
          expect(wrapper.emitted(Event.LOAD_ERROR)).toEqual([
            [{ errorCode: INVALID_SECURITY, errorMessage }],
          ]);
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

        it('emits payment-submit-success', () => {
          expect(wrapper.emitted(Event.PAYMENT_SUBMIT_SUCCESS)).toEqual([[{ refId }]]);
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
              Promise.resolve().then(() => handleError('error', null, iFrameErrorMessage)),
          };
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(iFrameErrorMessage);
        });

        it('tracks the payment_form_submitted error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.PAYMENT_SUBMITTED,
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

          expectLoadingExists();
        });
      });

      describe('when dispatching an empty event', () => {
        it('shows the loading icon', () => {
          window.dispatchEvent(new MessageEvent('message', { data: '' }));

          expectLoadingExists();
        });
      });

      describe('when dispatching an event with the wrong format', () => {
        it('shows the loading icon', () => {
          window.dispatchEvent(new MessageEvent('message', { data: [] }));

          expectLoadingExists();
        });
      });

      describe(`when dispatching a ${Action.RESIZE} event type`, () => {
        const height = 500;
        const data = JSON.stringify({ action: Action.RESIZE, height });

        beforeEach(() => {
          window.dispatchEvent(new MessageEvent('message', { data }));
        });

        it('does not show the loading icon', () => {
          expectLoadingDoesNotExist();
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

    describe('handleErrorMessage', () => {
      describe('server-validation-error', () => {
        const errorDetails = {
          key: 'error',
          code: 'unknown',
          message: 'Credit card expiry date should be in future',
        };

        beforeEach(() => {
          window.Z = {
            runAfterRender: (fn) => fn(),
            sendErrorMessageToHpm: jest.fn(),
            renderWithErrorHandler: (params, _, paymentFormSubmitted, handleErrorMessage) =>
              Promise.resolve().then(() =>
                handleErrorMessage(errorDetails.key, errorDetails.code, errorDetails.message),
              ),
          };
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('does not show the loading icon', () => {
          expectLoadingDoesNotExist();
        });

        it('shows alert with error message', () => {
          expect(findAlert().text()).toBe(errorDetails.message);
        });

        it('emits server-validation-error', () => {
          expect(wrapper.emitted(Event.SERVER_VALIDATION_ERROR)).toEqual([[errorDetails]]);
        });

        it('tracks server-validation-error event', () => {
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.PAYMENT_SUBMITTED,
            property: errorDetails.message,
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });

      describe('client-validation-error', () => {
        const errorDetails = {
          key: 'creditCardNumber',
          code: '001',
          message: 'Required field empty',
        };

        beforeEach(() => {
          window.Z = {
            runAfterRender: (fn) => fn(),
            sendErrorMessageToHpm: jest.fn(),
            renderWithErrorHandler: (params, _, paymentFormSubmitted, handleErrorMessage) =>
              Promise.resolve().then(() =>
                handleErrorMessage(errorDetails.key, errorDetails.code, errorDetails.message),
              ),
          };
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('does not show the loading icon', () => {
          expectLoadingDoesNotExist();
        });

        it('does not show alert with error message', () => {
          expect(findAlert().exists()).toBe(false);
        });

        it('invokes sendErrorMessageToHpm with the correct params', () => {
          expect(window.Z.sendErrorMessageToHpm).toHaveBeenCalledTimes(1);
          expect(window.Z.sendErrorMessageToHpm).toHaveBeenCalledWith(
            errorDetails.key,
            errorDetails.message,
          );
        });

        it('emits client-validation-error', () => {
          expect(wrapper.emitted(Event.CLIENT_VALIDATION_ERROR)).toEqual([[errorDetails]]);
        });

        it('tracks client-validation-error event', () => {
          expect(trackingSpy).toHaveBeenLastCalledWith(
            ZUORA_EVENT_CATEGORY,
            TrackingEvent.ERROR_CLIENT,
            {
              label: TrackingLabel.PAYMENT_SUBMITTED,
              property: errorDetails.message,
              category: ZUORA_EVENT_CATEGORY,
            },
          );
        });
      });
    });

    describe('submit', () => {
      beforeEach(() => {
        window.Z = {
          submit: () => {},
        };
        createComponent();
        wrapper.vm.zuoraScriptEl.onload();
        wrapper.vm.submit();
      });

      it('emits payment-submission-processing', () => {
        expect(wrapper.emitted(Event.PAYMENT_SUBMISSION_PROCESSING)).toHaveLength(1);
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

          expectLoadingExists();
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
          expectLoadingDoesNotExist();
        });

        it('shows zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(false);
        });

        it('applies the correct style', () => {
          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${initialHeight}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('emits loaded', () => {
          expect(wrapper.emitted(Event.LOADED)).toHaveLength(1);
        });

        it('tracks frame_loaded event', () => {
          expect(trackingSpy).toHaveBeenCalledWith(
            ZUORA_EVENT_CATEGORY,
            TrackingEvent.IFRAME_LOADED,
            {
              category: ZUORA_EVENT_CATEGORY,
            },
          );
        });

        it('calls the Z method with the correct params', () => {
          expect(window.Z.renderWithErrorHandler).toHaveBeenCalledTimes(1);
          expect(window.Z.renderWithErrorHandler).toHaveBeenCalledWith(
            expect.objectContaining({
              location: btoa(window.location.href),
              user_id: currentUserId,
              someData: 'some-data',
              submitEnabled: 'true',
            }),
            expect.anything(),
            expect.any(Function),
            expect.any(Function),
          );
        });
      });

      describe('when resolved with an error', () => {
        const error = 'error';

        beforeEach(() => {
          jest.spyOn(Api, 'fetchPaymentFormParams').mockResolvedValue({ data: { errors: error } });
          createComponent();
          wrapper.vm.zuoraScriptEl.onload();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe(ERROR_LOADING_PAYMENT_FORM);
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(1);
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.FETCH_PARAMS,
            property: error,
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
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.FETCH_PARAMS,
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
          expectLoadingDoesNotExist();
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
          expect(trackingSpy).toHaveBeenCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.FETCH_PARAMS,
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
          expectLoadingExists();
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
          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${initialHeight}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('does not show an error alert', () => {
          expect(findAlert().exists()).toBe(false);
        });

        it('emits success', () => {
          expect(wrapper.emitted(Event.SUCCESS)).toHaveLength(1);
        });

        it('tracks the payment_method_validate success event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(
            ZUORA_EVENT_CATEGORY,
            TrackingEvent.SUCCESS,
            {
              label: TrackingLabel.PAYMENT_VALIDATE,
              property: `payment_method_id: ${refId}`,
              category: ZUORA_EVENT_CATEGORY,
            },
          );
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

        it('tracks the payment_method_validate error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.PAYMENT_VALIDATE,
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

        it('tracks the payment_method_validate error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.PAYMENT_VALIDATE,
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
          expectLoadingDoesNotExist();
        });

        it('shows an error alert', () => {
          expect(findAlert().text()).toBe('Request failed with status code 401');
        });

        it('does not show zuora_payment', () => {
          expect(findZuoraPayment().classes('gl-visibility-hidden')).toBe(false);
        });

        it('applies the correct style', () => {
          expect(findZuoraPayment().attributes('style')).toBe(
            `height: ${initialHeight}px; min-height: ${DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT};`,
          );
        });

        it('tracks the payment_form_fetch_params error event', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(2);
          expect(trackingSpy).toHaveBeenLastCalledWith(ZUORA_EVENT_CATEGORY, TrackingEvent.ERROR, {
            label: TrackingLabel.PAYMENT_VALIDATE,
            property: 'Request failed with status code 401',
            category: ZUORA_EVENT_CATEGORY,
          });
        });
      });
    });
  });
});
