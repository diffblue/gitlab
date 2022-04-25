import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AccountVerificationModal from 'ee/billings/components/account_verification_modal.vue';
import Zuora from 'ee/billings/components/zuora.vue';
import { verificationModalDefaultGon, verificationModalDefaultProps } from '../mock_data';

describe('Account verification modal', () => {
  let wrapper;

  const originalGon = window.gon;

  const createComponent = () => {
    wrapper = shallowMount(AccountVerificationModal, {
      propsData: verificationModalDefaultProps,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent({ ref: 'modal' });

  const zuoraSubmitSpy = jest.fn();

  beforeEach(() => {
    window.gon = {
      ...originalGon,
      ...verificationModalDefaultGon,
    };
  });

  afterEach(() => {
    window.gon = originalGon;
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

  describe('when zuora emits success', () => {
    beforeEach(() => {
      createComponent();
    });

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
