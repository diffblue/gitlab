import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import PhoneVerification from 'ee/users/identity_verification/components/phone_verification.vue';
import InternationalPhoneInput from 'ee/users/identity_verification/components/international_phone_input.vue';
import VerifyPhoneVerificationCode from 'ee/users/identity_verification/components/verify_phone_verification_code.vue';

describe('Phone Verification component', () => {
  let wrapper;

  const PHONE_NUMBER = {
    country: 'US',
    internationalDialCode: '1',
    number: '555',
  };

  const findInternationalPhoneInput = () => wrapper.findComponent(InternationalPhoneInput);
  const findVerifyCodeInput = () => wrapper.findComponent(VerifyPhoneVerificationCode);
  const findPhoneExemptionLink = () =>
    wrapper.findByText(s__('IdentityVerification|Verify with a credit card instead?'));

  const createComponent = (providedProps = {}) => {
    wrapper = shallowMountExtended(PhoneVerification, {
      provide: {
        offerPhoneNumberExemption: true,
        ...providedProps,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('When component loads', () => {
    it('should display InternationalPhoneInput component', () => {
      expect(findInternationalPhoneInput().exists()).toBe(true);
      expect(findInternationalPhoneInput().isVisible()).toBe(true);
    });

    it('should hide VerifyPhoneVerificationCode component', () => {
      expect(findVerifyCodeInput().exists()).toBe(true);
      expect(findVerifyCodeInput().isVisible()).toBe(false);
    });
  });

  describe('On next', () => {
    beforeEach(async () => {
      await findInternationalPhoneInput().vm.$emit('next', PHONE_NUMBER);
    });

    it('should hide InternationalPhoneInput component', () => {
      expect(findInternationalPhoneInput().isVisible()).toBe(false);
    });

    it('should display VerifyPhoneVerificationCode component', () => {
      expect(findVerifyCodeInput().isVisible()).toBe(true);
      expect(findVerifyCodeInput().props()).toMatchObject({ latestPhoneNumber: PHONE_NUMBER });
    });

    describe('On back', () => {
      beforeEach(async () => {
        await findVerifyCodeInput().vm.$emit('back');
      });

      it('should display InternationalPhoneInput component', () => {
        expect(findInternationalPhoneInput().isVisible()).toBe(true);
      });

      it('should hide PhoneVerificationCodeInput component', () => {
        expect(findVerifyCodeInput().isVisible()).toBe(false);
      });
    });
  });

  describe('On verified', () => {
    beforeEach(async () => {
      await findVerifyCodeInput().vm.$emit('verified');
    });

    it('should emit completed event', () => {
      expect(wrapper.emitted('completed')).toHaveLength(1);
    });
  });

  describe('On skip-verification', () => {
    beforeEach(async () => {
      await findInternationalPhoneInput().vm.$emit('skip-verification');
    });

    it('should emit completed event', () => {
      expect(wrapper.emitted('completed')).toHaveLength(1);
    });
  });

  describe('when phone exemption is not offered', () => {
    beforeEach(() => {
      createComponent({ offerPhoneNumberExemption: false });
    });

    it('does not show a link to request a phone exemption', () => {
      expect(findPhoneExemptionLink().exists()).toBe(false);
    });
  });

  describe('when phone exemption is offered', () => {
    it('shows a link to request a phone exemption', () => {
      expect(findPhoneExemptionLink().exists()).toBe(true);
    });

    it('emits an `exemptionRequested` event when clicking the link', () => {
      findPhoneExemptionLink().vm.$emit('click');

      expect(wrapper.emitted('exemptionRequested')).toHaveLength(1);
    });
  });
});
