import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlButton, GlFormInput, GlFormGroup, GlLoadingIcon, GlAlert, GlLink } from '@gitlab/ui';
import PromoCodeInput from 'ee/subscriptions/new/components//promo_code_input.vue';
import { PROMO_CODE_TERMS_LINK } from 'ee/subscriptions/new/constants';

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
    expect(findPromoCodeInput().attributes('disabled')).toBeDefined();
    expect(findApplyButton().attributes('disabled')).toBeDefined();
  };

  beforeEach(() => {
    createComponent();
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

  describe('when parent form is in loading state', () => {
    it('renders the correct state', async () => {
      enterPromoCode();
      wrapper.setProps({ isParentFormLoading: true, isApplyingPromoCode: false });

      await nextTick();

      assertDisabledState();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
    });
  });

  describe('when applying promo code', () => {
    it('renders the correct state', async () => {
      enterPromoCode();
      wrapper.setProps({ isParentFormLoading: true, isApplyingPromoCode: true });

      await nextTick();

      assertDisabledState();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findSuccessAlert().exists()).toBe(false);
    });
  });

  describe('when promo code is successful', () => {
    it('renders the correct state', async () => {
      enterPromoCode();
      wrapper.setProps({ showSuccessAlert: true });

      await nextTick();

      assertDisabledState();
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows success alert', async () => {
      enterPromoCode();
      wrapper.setProps({ showSuccessAlert: true });

      await nextTick();

      const successAlert = findSuccessAlert();
      expect(successAlert.exists()).toBe(true);
      expect(successAlert.text()).toBe(
        'Coupon has been applied and by continuing with your purchase, you accept and agree to the Coupon Terms.',
      );
      expect(successAlert.findComponent(GlLink).attributes('href')).toBe(PROMO_CODE_TERMS_LINK);
    });
  });

  describe('when promo code is successful and cannot show the success alert', () => {
    it('does not show success alert', async () => {
      enterPromoCode();
      wrapper.setProps({ showSuccessAlert: false });

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

      wrapper.setProps({
        errorMessage: 'Error :(',
        isParentFormLoading: true,
        isApplyingPromoCode: true,
      });
      await nextTick();

      assertDisabledState();
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findErrorMessage().exists()).toBe(false);
    });
  });

  it('disables the apply CTA when there is no promo code', () => {
    expect(findApplyButton().attributes('disabled')).toBeDefined();
  });

  it('enables the apply CTA when there is a promo code', async () => {
    enterPromoCode();
    await nextTick();

    expect(findApplyButton().attributes('disabled')).toBeUndefined();
  });
});
