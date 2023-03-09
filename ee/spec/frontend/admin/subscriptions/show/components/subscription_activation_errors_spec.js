import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionActivationErrors, {
  testIds,
  i18n,
  links,
} from 'ee/admin/subscriptions/show/components/subscription_activation_errors.vue';
import {
  CONNECTIVITY_ERROR,
  EXPIRED_LICENSE_SERVER_ERROR,
  INVALID_CODE_ERROR,
  SUBSCRIPTION_NOT_FOUND_SERVER_ERROR,
  SUBSCRIPTION_OVERAGES_SERVER_ERROR_REGEX,
  SUBSCRIPTION_INSUFFICIENT_TRUE_UP_SERVER_ERROR_REGEX,
} from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const GENERAL_ERROR_MESSAGE = 'A fake error';

const SUBSCRIPTION_OVERAGES_SERVER_ERROR = `This GitLab installation currently has 22 active users, exceeding this license's limit of 18 by 4 users. Please add a license for at least 22 users or contact sales at https://about.gitlab.com/sales/`;
const EXPECTED_SUBSCRIPTION_OVERAGES_CLIENTSIDE_ERROR = `Your current GitLab installation has 22 active users, which exceeds your new subscription seat count of 18 by 4. To activate your new subscription, purchase an additional 4 seats, or deactivate or block 4 users. For further assistance, contact GitLab support.`;

const SUBSCRIPTION_INSUFFICIENT_TRUE_UP_SERVER_ERROR = `You have applied a True-up for 1 user but you need one for 4 users. Please contact sales at https://about.gitlab.com/sales/`;
const EXPECTED_SUBSCRIPTION_INSUFFICIENT_TRUE_UP_CLIENTSIDE_ERROR = `You have applied a true-up for 1 user but you need one for 4 users. To pay for seat overages, contact your sales representative. For further assistance, contact GitLab support.`;

describe('SubscriptionActivationErrors', () => {
  let wrapper;

  const findConnectivityErrorAlert = () => wrapper.findByTestId(testIds.CONNECTIVITY_ERROR_ALERT);
  const findExpiredLicenseErrorAlert = () => wrapper.findByTestId(testIds.EXPIRED_ERROR_ALERT);
  const findGeneralErrorAlert = () => wrapper.findByTestId(testIds.GENERAL_ERROR_ALERT);
  const findInvalidActivationCode = () =>
    wrapper.findByTestId(testIds.INVALID_ACTIVATION_ERROR_ALERT);
  const findSubscriptionOveragesAlert = () =>
    wrapper.findByTestId(testIds.SUBSCRIPTION_OVERAGES_ERROR_ALERT);
  const findSubscriptionTrueUpOveragesAlert = () =>
    wrapper.findByTestId(testIds.TRUE_UP_OVERAGES_ERROR_ALERT);
  const findSubscriptionNotFoundAlert = () =>
    wrapper.findByTestId(testIds.SUBSCRIPTION_NOT_FOUND_ERROR_ALERT);
  const findRoot = () => wrapper.findByTestId(testIds.SUBSCRIPTION_ACTIVATION_ROOT);

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

  describe('with no error', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not render the component', () => {
      expect(findRoot().exists()).toBe(false);
    });
  });

  describe('with error', () => {
    it('support link is correct', () => {
      expect(links.supportLink).toMatch(
        /https:\/\/about.gitlab.(com|cn)\/support\/#contact-support/,
      );
    });

    describe.each([
      {
        error: CONNECTIVITY_ERROR,
        title: i18n.CONNECTIVITY_ERROR_TITLE,
        text: i18n.CONNECTIVITY_ERROR_MESSAGE,
        helpLinks: [links.troubleshootingHelpLink],
        testId: testIds.CONNECTIVITY_ERROR_ALERT,
      },
      {
        error: SUBSCRIPTION_OVERAGES_SERVER_ERROR,
        title: i18n.SUBSCRIPTION_OVERAGES_ERROR_TITLE,
        text: EXPECTED_SUBSCRIPTION_OVERAGES_CLIENTSIDE_ERROR,
        helpLinks: [
          links.addSeats,
          links.deactivateUser,
          links.blockUser,
          links.licenseSupportLink,
        ],
        testId: testIds.SUBSCRIPTION_OVERAGES_ERROR_ALERT,
      },
      {
        error: SUBSCRIPTION_INSUFFICIENT_TRUE_UP_SERVER_ERROR,
        title: i18n.TRUE_UP_OVERAGES_ERROR_TITLE,
        text: EXPECTED_SUBSCRIPTION_INSUFFICIENT_TRUE_UP_CLIENTSIDE_ERROR,
        helpLinks: [links.licenseSupportLink],
        testId: testIds.TRUE_UP_OVERAGES_ERROR_ALERT,
      },
      {
        error: SUBSCRIPTION_NOT_FOUND_SERVER_ERROR,
        title: i18n.SUBSCRIPTION_NOT_FOUND_ERROR_TITLE,
        text: i18n.SUBSCRIPTION_NOT_FOUND_ERROR_MESSAGE,
        helpLinks: [links.purchaseSubscriptionLink, links.supportLink],
        testId: testIds.SUBSCRIPTION_NOT_FOUND_ERROR_ALERT,
      },
      {
        error: EXPIRED_LICENSE_SERVER_ERROR,
        title: i18n.EXPIRED_LICENSE_ERROR_TITLE,
        text: i18n.EXPIRED_LICENSE_ERROR_MESSAGE,
        helpLinks: [links.purchaseSubscriptionLink, links.supportLink],
        testId: testIds.EXPIRED_ERROR_ALERT,
      },
      {
        error: INVALID_CODE_ERROR,
        title: i18n.GENERAL_ACTIVATION_ERROR_TITLE,
        text: i18n.INVALID_ACTIVATION_CODE,
        helpLinks: [links.subscriptionActivationHelpLink],
        testId: testIds.INVALID_ACTIVATION_ERROR_ALERT,
      },
      {
        error: GENERAL_ERROR_MESSAGE,
        title: i18n.GENERAL_ACTIVATION_ERROR_TITLE,
        text: i18n.GENERAL_ACTIVATION_ERROR_MESSAGE,
        helpLinks: [links.subscriptionActivationHelpLink, links.supportLink],
        testId: testIds.GENERAL_ERROR_ALERT,
      },
    ])('error message: $error', ({ error, helpLinks, text, title, testId }) => {
      beforeEach(() => {
        createComponent({ props: { error } });
      });

      it('displays correct content', () => {
        const alert = wrapper.findByTestId(testId);

        expect(alert.props('title')).toBe(title);
        expect(alert.text()).toMatchInterpolatedText(text);
        helpLinks.forEach((link, index) => {
          expect(alert.findAllComponents(GlLink).at(index).attributes('href')).toBe(link);
        });
      });

      it('does not show other alerts', () => {
        expect(findConnectivityErrorAlert().exists()).toBe(error === CONNECTIVITY_ERROR);
        expect(findSubscriptionOveragesAlert().exists()).toBe(
          SUBSCRIPTION_OVERAGES_SERVER_ERROR_REGEX.test(error),
        );
        expect(findSubscriptionTrueUpOveragesAlert().exists()).toBe(
          SUBSCRIPTION_INSUFFICIENT_TRUE_UP_SERVER_ERROR_REGEX.test(error),
        );
        expect(findSubscriptionNotFoundAlert().exists()).toBe(
          error === SUBSCRIPTION_NOT_FOUND_SERVER_ERROR,
        );
        expect(findExpiredLicenseErrorAlert().exists()).toBe(
          error === EXPIRED_LICENSE_SERVER_ERROR,
        );
        expect(findGeneralErrorAlert().exists()).toBe(error === 'A fake error');
        expect(findInvalidActivationCode().exists()).toBe(error === INVALID_CODE_ERROR);
      });
    });
  });
});
