import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import CreditCardVerification from 'ee/users/identity_verification/components/credit_card_verification.vue';

describe('CreditCardVerification', () => {
  let wrapper;

  const findZuora = () => wrapper.findComponent(Zuora);
  const findSubmitButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMount(CreditCardVerification, {
      provide: { creditCard: { formId: 'form_id', userId: 927 } },
      propsData: { completed: false },
    });
  };

  afterEach(() => {
    wrapper.destroy();
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
