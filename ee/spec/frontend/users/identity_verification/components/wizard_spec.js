import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import IdentityVerificationWizard from 'ee/users/identity_verification/components/wizard.vue';
import VerificationStep from 'ee/users/identity_verification/components/verification_step.vue';
import CreditCardVerification from 'ee/users/identity_verification/components/credit_card_verification.vue';
import PhoneVerification from 'ee/users/identity_verification/components/phone_verification.vue';
import EmailVerification from 'ee/users/identity_verification/components/email_verification.vue';
import { I18N_GENERIC_ERROR } from 'ee/users/identity_verification/constants';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('IdentityVerificationWizard', () => {
  let wrapper;
  let axiosMock;

  const DEFAULT_PROVIDE = {
    verificationStatePath: '/users/identity_verification/verification_state',
    successfulVerificationPath: '/users/identity_verification/success',
    phoneExemptionPath: '/users/identity_verification/toggle_phone_exemption',
  };

  const createComponent = ({ provide } = { provide: {} }) => {
    wrapper = shallowMount(IdentityVerificationWizard, {
      provide: { ...DEFAULT_PROVIDE, ...provide },
    });
  };

  const findSteps = () => wrapper.findAllComponents(VerificationStep);
  const findHeader = () => wrapper.find('h2');
  const findDescription = () => wrapper.find('p');
  const findNextButton = () => wrapper.findComponent(GlButton);

  const mockVerificationState = (mockState) => {
    axiosMock.onGet(DEFAULT_PROVIDE.verificationStatePath).replyOnce(HTTP_STATUS_OK, {
      verification_methods: Object.keys(mockState),
      verification_state: mockState,
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    createAlert.mockClear();
  });

  describe('Default', () => {
    beforeEach(async () => {
      mockVerificationState({ credit_card: false, phone: false, email: false });
      createComponent();
      await waitForPromises();
    });

    it('displays the header', () => {
      expect(findHeader().text()).toBe(s__('IdentityVerification|Help us keep GitLab secure'));
    });

    it('displays the description', () => {
      expect(findDescription().text()).toBe(
        s__(
          "IdentityVerification|For added security, you'll need to verify your identity in a few quick steps.",
        ),
      );
    });

    it('renders the correct verification method components in order', () => {
      expect(findSteps()).toHaveLength(3);
      expect(findSteps().at(0).findComponent(CreditCardVerification).exists()).toBe(true);
      expect(findSteps().at(1).findComponent(PhoneVerification).exists()).toBe(true);
      expect(findSteps().at(2).findComponent(EmailVerification).exists()).toBe(true);
    });

    it('renders steps with correct number and title', () => {
      expect(findSteps().at(0).props('title')).toBe('Step 1: Verify a payment method');
      expect(findSteps().at(1).props('title')).toBe('Step 2: Verify phone number');
      expect(findSteps().at(2).props('title')).toBe('Step 3: Verify email address');
    });
  });

  describe('Active verification step', () => {
    describe('when all steps are incomplete', () => {
      beforeEach(async () => {
        mockVerificationState({ credit_card: false, phone: false, email: false });
        createComponent();
        await waitForPromises();
      });

      it('is the first step', () => {
        expect(findSteps().at(0).props('isActive')).toBe(true);
        expect(findSteps().at(1).props('isActive')).toBe(false);
      });
    });

    describe('when some steps are complete', () => {
      beforeEach(async () => {
        mockVerificationState({ credit_card: true, phone: false, email: true });
        createComponent();
        await waitForPromises();
      });

      it('shows the incomplete steps at the end', () => {
        expect(findSteps().at(0).props('isActive')).toBe(false);
        expect(findSteps().at(1).props('isActive')).toBe(false);
        expect(findSteps().at(2).props('isActive')).toBe(true);

        expect(findSteps().at(0).props('title')).toBe('Step 1: Verify a payment method');
        expect(findSteps().at(1).props('title')).toBe('Step 2: Verify email address');
        expect(findSteps().at(2).props('title')).toBe('Step 3: Verify phone number');
      });
    });

    describe('when all steps are complete', () => {
      beforeEach(async () => {
        mockVerificationState({ credit_card: true, phone: true, email: true });
        createComponent();
        await waitForPromises();
      });

      it('shows all steps as completed', () => {
        expect(findSteps().at(0).props('completed')).toBe(true);
        expect(findSteps().at(1).props('completed')).toBe(true);
        expect(findSteps().at(2).props('completed')).toBe(true);
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

    const expectAllMethodsToBeCompleted = (stepWrappers) => {
      stepWrappers.forEach((stepWrapper) => {
        expect(stepWrapper.props('completed')).toBe(true);
      });
    };

    beforeEach(async () => {
      mockVerificationState({ credit_card: false, phone: false, email: false });
      createComponent();
      await waitForPromises();
    });

    it('goes from first to last one step at a time and redirects after all are completed', async () => {
      expect(findNextButton().exists()).toBe(false);

      expectMethodToBeActive(1, findSteps().wrappers);

      findSteps().at(0).findComponent(CreditCardVerification).vm.$emit('completed');
      await nextTick();

      expectMethodToBeActive(2, findSteps().wrappers);

      findSteps().at(1).findComponent(PhoneVerification).vm.$emit('completed');
      await nextTick();

      expectMethodToBeActive(3, findSteps().wrappers);

      findSteps().at(2).findComponent(EmailVerification).vm.$emit('completed');
      await nextTick();

      expect(findNextButton().exists()).toBe(true);

      expectAllMethodsToBeCompleted(findSteps().wrappers);
    });
  });

  describe('when the `exemptionRequested` event is fired from the phone verification step', () => {
    beforeEach(async () => {
      mockVerificationState({ phone: false, email: false });
      createComponent();
      await waitForPromises();
    });

    it('renders the credit card verification step instead of the phone verification step', async () => {
      axiosMock.onPatch(DEFAULT_PROVIDE.phoneExemptionPath).reply(HTTP_STATUS_OK, {
        verification_methods: ['credit_card', 'email'],
        verification_state: { credit_card: false, email: true },
      });

      wrapper.findComponent(PhoneVerification).vm.$emit('exemptionRequested');

      await axios.waitForAll();

      expect(wrapper.findComponent(PhoneVerification).exists()).toBe(false);
      expect(wrapper.findComponent(CreditCardVerification).exists()).toBe(true);
    });

    describe('when there is an error requesting a phone exemption', () => {
      it('renders the credit card verification step instead of the phone verification step', async () => {
        axiosMock.onPatch(DEFAULT_PROVIDE.phoneExemptionPath).reply(HTTP_STATUS_BAD_REQUEST, {});

        wrapper.findComponent(PhoneVerification).vm.$emit('exemptionRequested');

        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });
});
