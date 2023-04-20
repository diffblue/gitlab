import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Zuora, { Event } from 'ee/billings/components/zuora_simple.vue';
import CreditCardVerification, {
  EVENT_CATEGORY,
  EVENT_SUCCESS,
  EVENT_FAILED,
} from 'ee/users/identity_verification/components/credit_card_verification.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

describe('CreditCardVerification', () => {
  let trackingSpy;
  let wrapper;

  const findZuora = () => wrapper.findComponent(Zuora);
  const findSubmitButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMount(CreditCardVerification, {
      provide: { creditCard: { formId: 'form_id', userId: 927 } },
      propsData: { completed: false },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  afterEach(() => {
    unmockTracking();
  });

  it('renders the form', () => {
    createComponent();

    expect(findZuora().exists()).toBe(true);
    expect(findSubmitButton().exists()).toBe(true);
    expect(findSubmitButton().props('disabled')).toBe(true);
  });

  describe('when zuora emits success', () => {
    beforeEach(() => {
      createComponent();
      wrapper.findComponent(Zuora).vm.$emit('success');
    });

    it('emits a completed event', () => {
      expect(wrapper.emitted('completed')).toHaveLength(1);
    });

    it('tracks the event', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenLastCalledWith(EVENT_CATEGORY, EVENT_SUCCESS, {
        category: EVENT_CATEGORY,
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
