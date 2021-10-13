import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionActivationErrors, {
  subscriptionActivationHelpLink,
  troubleshootingHelpLink,
} from 'ee/admin/subscriptions/show/components/subscription_activation_errors.vue';
import {
  CONNECTIVITY_ERROR,
  generalActivationErrorMessage,
  generalActivationErrorTitle,
  invalidActivationCode,
  INVALID_CODE_ERROR,
  supportLink,
} from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('SubscriptionActivationErrors', () => {
  let wrapper;

  const findConnectivityErrorAlert = () => wrapper.findByTestId('connectivity-error-alert');
  const findGeneralErrorAlert = () => wrapper.findByTestId('general-error-alert');
  const findInvalidActivationCode = () => wrapper.findByTestId('invalid-activation-error-alert');
  const findRoot = () => wrapper.findByTestId('root');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionActivationErrors, {
        propsData: {
          ...props,
        },
        stubs: { GlSprintf },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with no error', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not render the component', () => {
      expect(findRoot().exists()).toBe(false);
    });
  });

  describe('connectivity error', () => {
    beforeEach(() => {
      createComponent({ props: { error: CONNECTIVITY_ERROR } });
    });

    it('shows some help links', () => {
      const alert = findConnectivityErrorAlert();

      expect(alert.findAllComponents(GlLink).at(0).attributes('href')).toBe(
        subscriptionActivationHelpLink,
      );
      expect(alert.findAllComponents(GlLink).at(1).attributes('href')).toBe(
        troubleshootingHelpLink,
      );
    });

    it('does not show other alerts', () => {
      expect(findGeneralErrorAlert().exists()).toBe(false);
      expect(findInvalidActivationCode().exists()).toBe(false);
    });
  });

  describe('invalid activation code error', () => {
    beforeEach(() => {
      createComponent({ props: { error: INVALID_CODE_ERROR } });
    });

    it('shows the alert', () => {
      expect(findInvalidActivationCode().attributes('title')).toBe(generalActivationErrorTitle);
    });

    it('shows a text to help the user', () => {
      expect(findInvalidActivationCode().text()).toMatchInterpolatedText(invalidActivationCode);
    });

    it('does not show other alerts', () => {
      expect(findConnectivityErrorAlert().exists()).toBe(false);
      expect(findGeneralErrorAlert().exists()).toBe(false);
    });
  });

  describe('general error', () => {
    beforeEach(() => {
      createComponent({ props: { error: 'A fake error' } });
    });

    it('shows a general error alert', () => {
      expect(findGeneralErrorAlert().props('title')).toBe(generalActivationErrorTitle);
    });

    it('shows some help links', () => {
      const alert = findGeneralErrorAlert();

      expect(alert.findAllComponents(GlLink).at(0).attributes('href')).toBe(
        subscriptionActivationHelpLink,
      );

      expect(alert.findAllComponents(GlLink).at(1).attributes('href')).toBe(supportLink);
    });

    it('shows a text to help the user', () => {
      expect(findGeneralErrorAlert().text()).toMatchInterpolatedText(generalActivationErrorMessage);
    });

    it('does not show the connectivity alert', () => {
      expect(findConnectivityErrorAlert().exists()).toBe(false);
      expect(findInvalidActivationCode().exists()).toBe(false);
    });
  });
});
