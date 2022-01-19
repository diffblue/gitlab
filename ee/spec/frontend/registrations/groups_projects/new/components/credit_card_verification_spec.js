import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import CreditCardVerification from 'ee/registrations/groups_projects/new/components/credit_card_verification.vue';
import { IFRAME_MINIMUM_HEIGHT } from 'ee/registrations/groups_projects/new/constants';
import { setHTMLFixture } from 'helpers/fixtures';

describe('CreditCardVerification', () => {
  let wrapper;
  let zuoraSubmitSpy;

  const IFRAME_URL = 'https://customers.gitlab.com/payment_forms/cc_registration_validation';
  const ALLOWED_ORIGIN = 'https://customers.gitlab.com';

  const createComponent = (completed = false) => {
    wrapper = shallowMount(CreditCardVerification, {
      provide: {
        completed,
        iframeUrl: IFRAME_URL,
        allowedOrigin: ALLOWED_ORIGIN,
      },
      stubs: {
        GlButton,
      },
    });
  };

  const verifyToggleEnabled = () =>
    wrapper.find({ ref: 'verifyToggle' }).attributes('enabled') === 'true';
  const createToggleEnabled = () =>
    wrapper.find({ ref: 'createToggle' }).attributes('enabled') === 'true';
  const findZuora = () => wrapper.find({ ref: 'zuora' });
  const findSubmitButton = () => wrapper.find({ ref: 'submitButton' });
  const toggleContainerHidden = () =>
    document.querySelector('.js-toggle-container').classList.contains('gl-display-none');

  beforeEach(() => {
    setHTMLFixture('<div class="js-toggle-container gl-display-none" />');
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the component is mounted', () => {
    it('enables the right toggles', () => {
      expect(verifyToggleEnabled()).toBe(true);
      expect(createToggleEnabled()).toBe(false);
    });

    it('hides the toggleContainer', () => {
      expect(toggleContainerHidden()).toBe(true);
    });

    it('renders the Zuora component with the right attributes', () => {
      expect(findZuora().exists()).toBe(true);
      expect(findZuora().attributes()).toMatchObject({
        iframeurl: IFRAME_URL,
        allowedorigin: ALLOWED_ORIGIN,
        initialheight: IFRAME_MINIMUM_HEIGHT.toString(),
      });
    });

    describe('when verification is completed', () => {
      beforeEach(() => {
        createComponent(true);
      });

      it('enables the right toggles', () => {
        expect(verifyToggleEnabled()).toBe(false);
        expect(createToggleEnabled()).toBe(true);
      });

      it('shows the toggleContainer', () => {
        expect(toggleContainerHidden()).toBe(false);
      });

      it('hides the Zuora component', () => {
        expect(findZuora().exists()).toBe(false);
      });
    });
  });

  describe('when the submit button is clicked', () => {
    beforeEach(() => {
      zuoraSubmitSpy = jest.fn();
      wrapper.vm.$refs.zuora = { submit: zuoraSubmitSpy };
      findSubmitButton().trigger('click');
    });

    it('calls the submit method of the Zuora component', () => {
      expect(zuoraSubmitSpy).toHaveBeenCalled();
    });
  });

  describe('when the Zuora component emits a success event', () => {
    beforeEach(() => {
      findZuora().vm.$emit('success');
    });

    it('enables the right toggles', () => {
      expect(verifyToggleEnabled()).toBe(false);
      expect(createToggleEnabled()).toBe(true);
    });

    it('shows the toggleContainer', () => {
      expect(toggleContainerHidden()).toBe(false);
    });

    it('hides the Zuora component', () => {
      expect(findZuora().exists()).toBe(false);
    });
  });
});
