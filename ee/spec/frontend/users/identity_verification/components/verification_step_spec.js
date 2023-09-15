import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VerificationStep from 'ee/users/identity_verification/components/verification_step.vue';

describe('VerificationStep', () => {
  let wrapper;

  const StepComponent = {
    name: 'step-component',
    template: '<p>Step</p>',
  };

  const DEFAULT_PROPS = {
    title: 'The Verification Step',
    completed: false,
    isActive: false,
  };

  const createComponent = ({ props } = { props: {} }) => {
    wrapper = shallowMountExtended(VerificationStep, {
      propsData: { ...DEFAULT_PROPS, ...props },
      slots: { default: StepComponent },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findTitle = () => wrapper.findByText(DEFAULT_PROPS.title);
  const findStep = () => wrapper.findComponent(StepComponent);

  describe('Default: completed: false, inactive: false', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the passed provided title', () => {
      expect(findTitle().exists()).toBe(true);
    });

    it('does not display completed icon', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('does not render the default child component', () => {
      expect(findStep().exists()).toBe(false);
    });
  });

  describe('completed prop is true', () => {
    beforeEach(() => {
      createComponent({ props: { completed: true } });
    });

    it('displays completed badge', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().props()).toMatchObject({
        variant: 'success',
        icon: 'check-circle-filled',
      });
    });
  });

  describe('isActive prop is true', () => {
    beforeEach(() => {
      createComponent({ props: { isActive: true } });
    });

    it('renders the default child component', () => {
      expect(findStep().exists()).toBe(true);
    });
  });
});
