import { shallowMount } from '@vue/test-utils';
import IdentityVerificationWizard from 'ee/users/identity_verification/components/wizard.vue';
import EmailVerification from 'ee/users/identity_verification/components/email_verification.vue';

describe('IdentityVerificationWizard', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(IdentityVerificationWizard);
  };

  const findHeader = () => wrapper.find('h2');
  const findEmailVerification = () => wrapper.findComponent(EmailVerification);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering the component', () => {
    it('contains a header', () => {
      expect(findHeader().text()).toBe('Help us keep GitLab secure');
    });

    it('renders the EmailVerification component', () => {
      expect(findEmailVerification().exists()).toBe(true);
    });
  });
});
