import { shallowMount } from '@vue/test-utils';

import IdentityVerificationWizard from 'ee/users/identity_verification/components/wizard.vue';
import PhoneVerification from 'ee/users/identity_verification/components/phone_verification.vue';

describe('Identity verification wizard component', () => {
  let wrapper;

  const findPhoneVerification = () => wrapper.findComponent(PhoneVerification);

  const createComponent = ({ props } = { props: {} }) => {
    wrapper = shallowMount(IdentityVerificationWizard, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('PhoneVerification', () => {
    it('should render PhoneVerification component', () => {
      createComponent();

      expect(findPhoneVerification().exists()).toBe(true);
    });
  });
});
