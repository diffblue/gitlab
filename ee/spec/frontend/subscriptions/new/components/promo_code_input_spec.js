import { mount } from '@vue/test-utils';
import { GlButton, GlFormInput, GlFormGroup } from '@gitlab/ui';
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

  it('emits an event on applying promo code', async () => {
    const samplePromoCode = 'sample-promo-code';

    findPromoCodeInput().vm.$emit('input', samplePromoCode);
    await findApplyButton().trigger('click');

    expect(wrapper.emitted('applyPromoCode')).toEqual([[samplePromoCode]]);
  });
});
