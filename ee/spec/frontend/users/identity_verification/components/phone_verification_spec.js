import { shallowMount } from '@vue/test-utils';

import InternationalPhoneInput from 'ee/users/identity_verification/components/international_phone_input.vue';
import PhoneVerification from 'ee/users/identity_verification/components/phone_verification.vue';

describe('Phone Verification component', () => {
  let wrapper;

  const findInternationalPhoneInput = () => wrapper.findComponent(InternationalPhoneInput);

  const createComponent = ({ props } = { props: {} }) => {
    wrapper = shallowMount(PhoneVerification, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('International Phone input', () => {
    it('should render InternationalPhoneInput component', () => {
      expect(findInternationalPhoneInput().exists()).toBe(true);
    });
  });
});
