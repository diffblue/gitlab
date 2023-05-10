import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import Zuora, { Event } from 'ee/billings/components/zuora_simple.vue';
import CreditCardVerification, {
  EVENT_CATEGORY,
  EVENT_SUCCESS,
  EVENT_FAILED,
} from 'ee/users/identity_verification/components/credit_card_verification.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { createAlert } from '~/alert';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { I18N_GENERIC_ERROR } from 'ee/users/identity_verification/constants';

jest.mock('~/alert');

const MOCK_VERIFY_CREDIT_CARD_PATH = '/mock/verify_credit_card/path';

describe('CreditCardVerification', () => {
  let trackingSpy;
  let wrapper;

  const findCheckForReuseLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findZuora = () => wrapper.findComponent(Zuora);
  const findSubmitButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMount(CreditCardVerification, {
      provide: {
        creditCard: {
          formId: 'form_id',
          userId: 927,
          verifyCreditCardPath: MOCK_VERIFY_CREDIT_CARD_PATH,
        },
      },
      propsData: { completed: false },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  afterEach(() => {
    createAlert.mockClear();
    unmockTracking();
  });

  it('renders the form', () => {
    createComponent();

    expect(findZuora().exists()).toBe(true);
    expect(findSubmitButton().exists()).toBe(true);
    expect(findSubmitButton().props('disabled')).toBe(true);
  });

  describe('when zuora emits success', () => {
    let axiosMock;

    beforeEach(() => {
      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    describe('when check for reuse request returns a successful response', () => {
      beforeEach(() => {
        axiosMock.onGet(MOCK_VERIFY_CREDIT_CARD_PATH).reply(HTTP_STATUS_OK);

        createComponent();
        findZuora().vm.$emit('success');
      });

      it('displays loading state', () => {
        expect(findCheckForReuseLoading().exists()).toBe(true);
        expect(findZuora().exists()).toBe(false);
      });

      it('emits a completed event', async () => {
        await waitForPromises();

        expect(wrapper.emitted('completed')).toHaveLength(1);
      });

      it('tracks the event', async () => {
        await waitForPromises();

        expect(trackingSpy).toHaveBeenCalledTimes(1);
        expect(trackingSpy).toHaveBeenLastCalledWith(EVENT_CATEGORY, EVENT_SUCCESS, {
          category: EVENT_CATEGORY,
        });
      });
    });

    describe('when check for reuse request returns an error', () => {
      const message = 'There was a problem with the credit card details you entered.';

      beforeEach(async () => {
        axiosMock
          .onGet(MOCK_VERIFY_CREDIT_CARD_PATH)
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, { message });

        createComponent();
        findZuora().vm.$emit('success');

        await waitForPromises();
      });

      it('does not emit a completed event', () => {
        expect(wrapper.emitted('completed')).toBeUndefined();
      });

      it('does not track a success event', () => {
        expect(trackingSpy).toHaveBeenCalledTimes(0);
      });

      it('re-displays the form and displays an alert with the returned message', async () => {
        expect(findCheckForReuseLoading().exists()).toBe(false);
        expect(findZuora().exists()).toBe(true);

        findZuora().vm.$emit('loading', false);

        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message,
        });
      });

      describe('when there is no returned message data', () => {
        beforeEach(async () => {
          axiosMock.onGet(MOCK_VERIFY_CREDIT_CARD_PATH).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          createComponent();
          findZuora().vm.$emit('success');

          await waitForPromises();
        });

        it('displays an alert with a generic message', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: I18N_GENERIC_ERROR,
            captureError: true,
            error: expect.any(Error),
          });
        });
      });
    });
  });

  describe('when zuora emits load error', () => {
    it('disables the submit button', () => {
      createComponent();

      wrapper.findComponent(Zuora).vm.$emit('load-error');

      expect(findSubmitButton().props('disabled')).toBe(true);
    });
  });

  describe.each([
    [Event.SERVER_VALIDATION_ERROR, { message: 'server error' }],
    [Event.CLIENT_VALIDATION_ERROR, { message: 'client error' }],
  ])('when zuora emits %s', (event, payload) => {
    beforeEach(() => {
      createComponent();
      wrapper.findComponent(Zuora).vm.$emit(event, payload);
    });

    it('tracks the event', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenLastCalledWith(EVENT_CATEGORY, EVENT_FAILED, {
        category: EVENT_CATEGORY,
        property: payload.message,
      });
    });
  });

  describe('clicking the submit button', () => {
    const zuoraSubmitSpy = jest.fn();

    beforeEach(() => {
      createComponent();

      wrapper.vm.$refs.zuora = { submit: zuoraSubmitSpy };

      findSubmitButton().vm.$emit('click');
    });

    it('calls the submit method of the Zuora component', () => {
      expect(zuoraSubmitSpy).toHaveBeenCalled();
    });
  });

  describe('submit button loading state', () => {
    beforeEach(() => {
      createComponent();
    });

    it("is disabled when Zuora component emits 'loading' event with true", async () => {
      findZuora().vm.$emit('loading', true);

      await nextTick();

      expect(findSubmitButton().props('disabled')).toBe(true);
    });

    it("is not disabled when <Zuora /> emits 'loading' event with false", async () => {
      findZuora().vm.$emit('loading', false);

      await nextTick();

      expect(findSubmitButton().props('disabled')).toBe(false);
    });
  });
});
