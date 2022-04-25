import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import AccountVerificationModal, {
  IFRAME_MINIMUM_HEIGHT,
} from 'ee/billings/components/account_verification_modal.vue';
import { verificationModalDefaultGon, verificationModalDefaultProps } from '../mock_data';

describe('Account verification modal', () => {
  let wrapper;

  const originalGon = window.gon;
  const findModal = () => wrapper.findComponent({ ref: 'modal' });

  const createComponent = () => {
    wrapper = shallowMount(AccountVerificationModal, {
      propsData: verificationModalDefaultProps,
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    window.gon = {
      ...originalGon,
      ...verificationModalDefaultGon,
      features: {
        useApiForPaymentValidation: true,
      },
    };
    return createComponent();
  });

  afterEach(() => {
    window.gon = originalGon;
    wrapper.destroy();
  });

  describe('with the feature flag', () => {
    it('renders the correct Zuora component', () => {
      expect(wrapper.findComponent(Zuora).props()).toEqual({
        currentUserId: 300,
        initialHeight: IFRAME_MINIMUM_HEIGHT,
        paymentFormId: 'payment-validation-page-id',
      });
    });

    it('passes the correct props to the button', () => {
      expect(findModal().props('actionPrimary').attributes).toMatchObject({
        disabled: false,
        variant: 'confirm',
      });
    });

    describe('when zuora emits success', () => {
      it('forwards the success event up', () => {
        wrapper.findComponent(Zuora).vm.$emit('success');

        expect(wrapper.emitted('success')).toHaveLength(1);
      });
    });
  });
});
