import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlButton, GlFormInput, GlFormGroup, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import PromoCodeInput from 'ee/subscriptions/new/components//promo_code_input.vue';

describe('PromoCodeInput', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(PromoCodeInput, {
      propsData: {
        ...props,
      },
    });
  };

  const findPromoCodeFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findPromoCodeInput = () => findPromoCodeFormGroup().findComponent(GlFormInput);
  const findApplyButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => findApplyButton().findComponent(GlLoadingIcon);
  const findSuccessAlert = () => wrapper.findComponent(GlAlert);
  const findErrorMessage = () => wrapper.find('.invalid-feedback');
  const samplePromoCode = 'sample-promo-code';
  const enterPromoCode = () => findPromoCodeInput().vm.$emit('input', samplePromoCode);

  const assertDisabledState = () => {
    expect(findPromoCodeInput().attributes('disabled')).toBe('disabled');
    expect(findApplyButton().attributes('disabled')).toBe('disabled');
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders promo code input', () => {
    expect(findPromoCodeFormGroup().exists()).toBe(true);
    expect(findApplyButton().exists()).toBe(true);
  });

  it('emits an event on changing promo code', async () => {
    enterPromoCode();
    await wrapper.find('input').trigger('change');

    expect(wrapper.emitted('promo-code-updated')).toHaveLength(1);
  });

  it('emits an event on applying promo code', async () => {
    enterPromoCode();

    await findApplyButton().vm.$emit('click');

    expect(wrapper.emitted('apply-promo-code')).toEqual([[samplePromoCode]]);
  });

  describe('when in loading state', () => {
    it('renders the correct state', async () => {
      enterPromoCode();
      wrapper.setProps({ applyingPromoCode: true });

      await nextTick();

      assertDisabledState();
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findSuccessAlert().exists()).toBe(false);
    });
  });

  describe('when promo code is successful', () => {
    it('renders the correct state', async () => {
      enterPromoCode();
      wrapper.setProps({ successMessage: 'Success :D', canShowSuccessAlert: true });

      await nextTick();

      assertDisabledState();
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when promo code is successful and cannot show the success alert', () => {
    it('does not show success alert', async () => {
      enterPromoCode();
      wrapper.setProps({ successMessage: 'Success :D', canShowSuccessAlert: false });

      await nextTick();

      expect(findSuccessAlert().exists()).toBe(false);
    });
  });

  describe('when promo code is unsuccessful', () => {
    it('renders the correct state', async () => {
      enterPromoCode();

      wrapper.setProps({ errorMessage: 'Error :(' });
      await nextTick();

      expect(findPromoCodeInput().attributes('disabled')).toBeUndefined();
      expect(findApplyButton().attributes('disabled')).toBeUndefined();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
      expect(findErrorMessage().text()).toBe('Error :(');
    });

    it(`doesn't show the error message when in loading state`, async () => {
      enterPromoCode();

      wrapper.setProps({ errorMessage: 'Error :(', applyingPromoCode: true });
      await nextTick();

      assertDisabledState();
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findErrorMessage().exists()).toBe(false);
    });
  });

  it('disables the apply CTA when there is no promo code', () => {
    expect(findApplyButton().attributes('disabled')).toBe('disabled');
  });

  it('enables the apply CTA when there is a promo code', async () => {
    enterPromoCode();
    await nextTick();

    expect(findApplyButton().attributes('disabled')).toBeUndefined();
  });
});
