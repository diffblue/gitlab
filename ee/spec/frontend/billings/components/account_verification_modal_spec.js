import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AccountVerificationModal from 'ee/billings/components/account_verification_modal.vue';

describe('Account verification modal', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AccountVerificationModal, {
      propsData: {
        iframeUrl: 'https://gitlab.com',
        allowedOrigin: 'https://gitlab.com',
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent({ ref: 'modal' });

  const zuoraSubmitSpy = jest.fn();

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the title', () => {
      expect(findModal().attributes('title')).toBe('Validate user account');
    });

    it('renders the description', () => {
      expect(wrapper.find('p').text()).toContain('To use free CI/CD minutes');
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
