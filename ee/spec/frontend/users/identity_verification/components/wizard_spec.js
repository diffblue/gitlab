import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { visitUrl } from '~/lib/utils/url_utility';
import IdentityVerificationWizard from 'ee/users/identity_verification/components/wizard.vue';
import VerificationStep from 'ee/users/identity_verification/components/verification_step.vue';
import CreditCardVerification from 'ee/users/identity_verification/components/credit_card_verification.vue';
import PhoneVerification from 'ee/users/identity_verification/components/phone_verification.vue';
import EmailVerification from 'ee/users/identity_verification/components/email_verification.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('IdentityVerificationWizard', () => {
  let wrapper;
  let steps;

  const DEFAULT_PROVIDE = {
    verificationSteps: ['creditCard', 'email'],
    initialVerificationState: { creditCard: false, email: false },
    successfulVerificationPath: '/users/identity_verification/success',
  };

  const createComponent = ({ provide } = { provide: {} }) => {
    wrapper = shallowMount(IdentityVerificationWizard, {
      provide: { ...DEFAULT_PROVIDE, ...provide },
    });

    steps = wrapper.findAllComponents(VerificationStep);
  };

  const findHeader = () => wrapper.find('h2');
  const findDescription = () => wrapper.find('p');

  describe('Default', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          verificationSteps: ['creditCard', 'phone', 'email'],
          initialVerificationState: { creditCard: false, phone: false, email: false },
        },
      });
    });

    it('displays the header', () => {
      expect(findHeader().text()).toBe(wrapper.vm.$options.i18n.pageTitle);
    });

    it('displays the description', () => {
      expect(findDescription().text()).toBe(wrapper.vm.$options.i18n.pageDescription);
    });

    it('renders the correct verification method components in order', () => {
      expect(steps).toHaveLength(3);
      expect(steps.at(0).findComponent(CreditCardVerification).exists()).toBe(true);
      expect(steps.at(1).findComponent(PhoneVerification).exists()).toBe(true);
      expect(steps.at(2).findComponent(EmailVerification).exists()).toBe(true);
    });

    it('renders steps with correct number and title', () => {
      expect(steps.at(0).props('title')).toBe('Step 1: Verify a payment method');
      expect(steps.at(1).props('title')).toBe('Step 2: Verify phone number');
      expect(steps.at(2).props('title')).toBe('Step 3: Verify email address');
    });
  });

  describe('Active verification step', () => {
    describe('when all steps are incomplete', () => {
      it('is the first step', () => {
        createComponent();

        expect(steps.at(0).props('isActive')).toBe(true);
        expect(steps.at(1).props('isActive')).toBe(false);
      });
    });

    describe('when some steps are complete', () => {
      it('shows the incomplete steps at the end', () => {
        createComponent({
          provide: {
            verificationSteps: ['creditCard', 'phone', 'email'],
            initialVerificationState: { creditCard: true, phone: false, email: true },
          },
        });

        expect(steps.at(0).props('isActive')).toBe(false);
        expect(steps.at(1).props('isActive')).toBe(false);
        expect(steps.at(2).props('isActive')).toBe(true);

        expect(steps.at(0).props('title')).toBe('Step 1: Verify a payment method');
        expect(steps.at(1).props('title')).toBe('Step 2: Verify email address');
        expect(steps.at(2).props('title')).toBe('Step 3: Verify phone number');
      });
    });

    describe('when all steps are complete', () => {
      it('is none of the steps', () => {
        createComponent({
          provide: {
            initialVerificationState: { creditCard: true, email: true },
          },
        });

        expect(steps.at(0).props('isActive')).toBe(false);
        expect(steps.at(1).props('isActive')).toBe(false);
      });
    });
  });

  describe('Progression of active step', () => {
    const expectMethodToBeActive = (activeMethodNumber, stepWrappers) => {
      stepWrappers.forEach((stepWrapper, index) => {
        const shouldBeActive = index + 1 === activeMethodNumber;
        expect(stepWrapper.props('isActive')).toBe(shouldBeActive);
      });
    };

    const expectNoActiveMethod = (stepWrappers) => {
      stepWrappers.forEach((stepWrapper) => {
        expect(stepWrapper.props('isActive')).toBe(false);
      });
    };

    beforeEach(() => {
      createComponent();
    });

    it('goes from first to last one step at a time and redirects after all are completed', async () => {
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout');

      expectMethodToBeActive(1, steps.wrappers);

      steps.at(0).findComponent(CreditCardVerification).vm.$emit('completed');
      await nextTick();

      expect(setTimeoutSpy).not.toHaveBeenCalled();
      expectMethodToBeActive(2, steps.wrappers);

      steps.at(1).findComponent(EmailVerification).vm.$emit('completed');
      await nextTick();

      expectNoActiveMethod(steps.wrappers);

      jest.runAllTimers();

      expect(setTimeoutSpy).toHaveBeenCalledTimes(1);
      expect(visitUrl).toHaveBeenCalledWith(DEFAULT_PROVIDE.successfulVerificationPath);
    });
  });

  describe('when there is only one step', () => {
    beforeEach(() => {
      createComponent({ provide: { verificationSteps: ['email'] } });
    });

    it('does not wrap the method component with a VerificationStep', () => {
      expect(steps).toHaveLength(0);
    });

    it('renders the method component', () => {
      expect(wrapper.findComponent(EmailVerification).exists()).toBe(true);
    });

    it('redirects to the successfulVerificationPath after completion', () => {
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout');
      wrapper.findComponent(EmailVerification).vm.$emit('completed');

      jest.runAllTimers();

      expect(setTimeoutSpy).toHaveBeenCalledTimes(1);
      expect(visitUrl).toHaveBeenCalledWith(DEFAULT_PROVIDE.successfulVerificationPath);
    });
  });
});
