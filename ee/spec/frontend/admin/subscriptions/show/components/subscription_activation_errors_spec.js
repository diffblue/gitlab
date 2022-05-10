import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionActivationErrors, {
  i18n,
  links,
} from 'ee/admin/subscriptions/show/components/subscription_activation_errors.vue';
import {
  CONNECTIVITY_ERROR,
  EXPIRED_LICENSE_SERVER_ERROR,
  invalidActivationCode,
  INVALID_CODE_ERROR,
} from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('SubscriptionActivationErrors', () => {
  let wrapper;

  const findConnectivityErrorAlert = () => wrapper.findByTestId('connectivity-error-alert');
  const findExpiredLicenseErrorAlert = () => wrapper.findByTestId('expired-error-alert');
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

    it('displays a help link', () => {
      const alert = findConnectivityErrorAlert();

      expect(alert.findComponent(GlLink).attributes('href')).toBe(links.troubleshootingHelpLink);
    });

    it('does not show other alerts', () => {
      expect(findExpiredLicenseErrorAlert().exists()).toBe(false);
      expect(findGeneralErrorAlert().exists()).toBe(false);
      expect(findInvalidActivationCode().exists()).toBe(false);
    });
  });

  describe('expired license error', () => {
    beforeEach(() => {
      createComponent({ props: { error: EXPIRED_LICENSE_SERVER_ERROR } });
    });

    it('displays a help link', () => {
      const alert = findExpiredLicenseErrorAlert();

      expect(alert.findComponent(GlLink).attributes('href')).toBe(
        links.purchaseSubscriptionLinkStart,
      );
    });

    it('does not show other alerts', () => {
      expect(findConnectivityErrorAlert().exists()).toBe(false);
      expect(findGeneralErrorAlert().exists()).toBe(false);
      expect(findInvalidActivationCode().exists()).toBe(false);
    });
  });

  describe('invalid activation code error', () => {
    beforeEach(() => {
      createComponent({ props: { error: INVALID_CODE_ERROR } });
    });

    it('shows the alert', () => {
      expect(findInvalidActivationCode().attributes('title')).toBe(
        i18n.GENERAL_ACTIVATION_ERROR_TITLE,
      );
    });

    it('shows a text to help the user', () => {
      expect(findInvalidActivationCode().text()).toMatchInterpolatedText(invalidActivationCode);
    });

    it('does not show other alerts', () => {
      expect(findExpiredLicenseErrorAlert().exists()).toBe(false);
      expect(findConnectivityErrorAlert().exists()).toBe(false);
      expect(findGeneralErrorAlert().exists()).toBe(false);
    });
  });

  describe('general error', () => {
    beforeEach(() => {
      createComponent({ props: { error: 'A fake error' } });
    });

    it('shows a general error alert', () => {
      expect(findGeneralErrorAlert().props('title')).toBe(i18n.GENERAL_ACTIVATION_ERROR_TITLE);
    });

    it('shows some help links', () => {
      const alert = findGeneralErrorAlert();

      expect(alert.findAllComponents(GlLink).at(0).attributes('href')).toBe(
        links.subscriptionActivationHelpLink,
      );

      expect(links.supportLink).toMatch(
        /https:\/\/about.gitlab.(com|cn)\/support\/#contact-support/,
      );

      expect(alert.findAllComponents(GlLink).at(1).attributes('href')).toBe(links.supportLink);
    });

    it('shows a text to help the user', () => {
      expect(findGeneralErrorAlert().text()).toMatchInterpolatedText(
        i18n.GENERAL_ACTIVATION_ERROR_MESSAGE,
      );
    });

    it('does not show the connectivity alert', () => {
      expect(findExpiredLicenseErrorAlert().exists()).toBe(false);
      expect(findConnectivityErrorAlert().exists()).toBe(false);
      expect(findInvalidActivationCode().exists()).toBe(false);
    });
  });
});
