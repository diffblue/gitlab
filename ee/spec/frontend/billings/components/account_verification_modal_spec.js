import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import AccountVerificationModal, {
  IFRAME_MINIMUM_HEIGHT,
} from 'ee/billings/components/account_verification_modal.vue';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import { verificationModalDefaultGon, verificationModalDefaultProps } from '../mock_data';

describe('Account verification modal', () => {
  let wrapper;

  const originalGon = window.gon;
  const findModal = () => wrapper.findComponent({ ref: 'modal' });
  const zuoraSubmitSpy = jest.fn();

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
    };
    createComponent();
  });

  afterEach(() => {
    window.gon = originalGon;
    wrapper.destroy();
  });

  describe('on creation', () => {
    it('renders the title', () => {
      expect(findModal().attributes('title')).toBe('Validate user account');
    });

    it('renders the description', () => {
      expect(wrapper.find('p').text()).toContain('To use free CI/CD minutes');
    });

    it('renders the Zuora component', () => {
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
  });

  describe('when zuora emits load error', () => {
    it('disables the CTA on the modal', async () => {
      wrapper.findComponent(Zuora).vm.$emit('load-error');

      await nextTick();

      expect(findModal().props('actionPrimary').attributes).toMatchObject({
        disabled: true,
        variant: 'confirm',
      });
    });
  });

  describe('when zuora emits success', () => {
    it('forwards the success event up', () => {
      wrapper.findComponent(Zuora).vm.$emit('success');

      expect(wrapper.emitted('success')).toHaveLength(1);
    });
  });

  describe('clicking the submit button', () => {
    beforeEach(() => {
      createComponent();
      wrapper.vm.$refs.zuora = { submit: zuoraSubmitSpy };
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
    });

    it('calls the submit method of the Zuora component', () => {
      expect(zuoraSubmitSpy).toHaveBeenCalled();
    });
  });
});
