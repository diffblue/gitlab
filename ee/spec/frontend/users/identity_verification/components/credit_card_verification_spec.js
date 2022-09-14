import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import CreditCardVerification from 'ee/users/identity_verification/components/credit_card_verification.vue';

describe('CreditCardVerification', () => {
  let wrapper;

  const originalGon = window.gon;

  const DEFAULT_PROVIDE = {
    creditCardCompleted: false,
    creditCardFormId: 'form_id',
  };

  const findZuora = () => wrapper.findComponent(Zuora);
  const findSubmitButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ options = {}, provide = {} } = {}) => {
    wrapper = shallowMount(CreditCardVerification, {
      provide: { ...DEFAULT_PROVIDE, ...provide },
      ...options,
    });
  };

  beforeEach(() => {
    window.gon = { current_user_id: 300 };
  });

  afterEach(() => {
    window.gon = originalGon;
    wrapper.destroy();
  });

  describe('user has not verified a credit card', () => {
    it('renders the form', () => {
      createComponent();

      expect(findZuora().exists()).toBe(true);
      expect(findSubmitButton().exists()).toBe(true);
      expect(findSubmitButton().props('disabled')).toBe(true);
    });
  });

  describe('user has already verified a credit card', () => {
    it('does not render the form', () => {
      createComponent({ provide: { creditCardCompleted: true } });

      expect(findZuora().exists()).toBe(false);
      expect(findSubmitButton().exists()).toBe(false);
    });
  });

  describe('when zuora emits success', () => {
    beforeEach(() => {
      createComponent();
      wrapper.findComponent(Zuora).vm.$emit('success');
    });

    it('emits a verified event', () => {
      expect(wrapper.emitted('verified')).toHaveLength(1);
    });

    it('hides the form', () => {
      expect(findZuora().exists()).toBe(false);
      expect(findSubmitButton().exists()).toBe(false);
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
