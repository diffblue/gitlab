import { GlSprintf, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import AccountVerificationModal, {
  IFRAME_MINIMUM_HEIGHT,
} from 'ee/billings/components/account_verification_modal.vue';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import { verificationModalDefaultGon, verificationModalDefaultProps } from '../mock_data';

describe('Account verification modal', () => {
  let wrapper;
  let zuoraSubmitMock;

  const findModal = () => wrapper.findComponent(GlModal);
  const findZuora = () => wrapper.findComponent(Zuora);

  const createComponent = () => {
    zuoraSubmitMock = jest.fn();

    wrapper = shallowMount(AccountVerificationModal, {
      propsData: verificationModalDefaultProps,
      stubs: {
        GlSprintf,
        Zuora: stubComponent(Zuora, {
          methods: {
            submit: zuoraSubmitMock,
          },
        }),
      },
    });
  };

  beforeEach(() => {
    window.gon = verificationModalDefaultGon;
    createComponent();
  });

  describe('on creation', () => {
    it('renders the title', () => {
      expect(findModal().attributes('title')).toBe('Validate user account');
    });

    it('renders the description', () => {
      expect(wrapper.find('p').text()).toContain('To use free CI/CD minutes');
    });

    it('renders the Zuora component', () => {
      expect(findZuora().props()).toEqual({
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
      findZuora().vm.$emit('load-error');

      await nextTick();

      expect(findModal().props('actionPrimary').attributes).toMatchObject({
        disabled: true,
        variant: 'confirm',
      });
    });
  });

  describe('when zuora emits success', () => {
    it('forwards the success event up', () => {
      findZuora().vm.$emit('success');

      expect(wrapper.emitted('success')).toHaveLength(1);
    });
  });

  describe('when modal emits change', () => {
    it('forwards the change event up', () => {
      findModal().vm.$emit('change');

      expect(wrapper.emitted('change')).toHaveLength(1);
    });
  });

  describe('clicking the submit button', () => {
    beforeEach(() => {
      createComponent();
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
    });

    it('calls the submit method of the Zuora component', () => {
      expect(zuoraSubmitMock).toHaveBeenCalled();
    });
  });
});
