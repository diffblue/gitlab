import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import SubscriptionManagementApp from 'ee/admin/subscriptions/show/components/app.vue';
import SubscriptionActivationCard from 'ee/admin/subscriptions/show/components/subscription_activation_card.vue';
import SubscriptionBreakdown from 'ee/admin/subscriptions/show/components/subscription_breakdown.vue';
import {
  noActiveSubscription,
  subscriptionActivationNotificationText,
  subscriptionActivationFutureDatedNotificationTitle,
  subscriptionHistoryFailedTitle,
  subscriptionHistoryFailedMessage,
  currentSubscriptionsEntryName,
  historySubscriptionsEntryName,
  subscriptionMainTitle,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
} from 'ee/admin/subscriptions/show/constants';
import getCurrentLicense from 'ee/admin/subscriptions/show/graphql/queries/get_current_license.query.graphql';
import getLicenseHistory from 'ee/admin/subscriptions/show/graphql/queries/get_license_history.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import { license, subscriptionHistory } from '../mock_data';

Vue.use(VueApollo);

describe('SubscriptionManagementApp', () => {
  // March 16th, 2020
  useFakeDate(2021, 2, 16);

  let wrapper;

  const findActivateSubscriptionCard = () => wrapper.findComponent(SubscriptionActivationCard);
  const findSubscriptionBreakdown = () => wrapper.findComponent(SubscriptionBreakdown);
  const findSubscriptionActivationTitle = () =>
    wrapper.findByTestId('subscription-activation-title');
  const findSubscriptionMainTitle = () => wrapper.findByTestId('subscription-main-title');
  const findSubscriptionActivationSuccessAlert = () =>
    wrapper.findByTestId('subscription-activation-success-alert');
  const findSubscriptionFetchErrorAlert = () =>
    wrapper.findByTestId('subscription-fetch-error-alert');
  const findExportLicenseUsageFileLink = () => wrapper.findComponent(GlButton);

  let currentSubscriptionResolver;
  let subscriptionHistoryResolver;
  const createMockApolloProvider = ([subscriptionResolver, historyResolver]) => {
    Vue.use(VueApollo);
    return createMockApollo([
      [getCurrentLicense, subscriptionResolver],
      [getLicenseHistory, historyResolver],
    ]);
  };

  const createComponent = (props = {}, resolverMock) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionManagementApp, {
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          licenseUsageFilePath: 'about:blank',
          ...props,
        },
        stubs: {
          GlSprintf,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when failing to fetch subcriptions', () => {
    describe('when failing to fetch history subcriptions', () => {
      describe.each`
        currentFails | historyFails
        ${true}      | ${false}
        ${false}     | ${true}
        ${true}      | ${true}
      `(
        'with current subscription failing to fetch=$currentFails and history subscriptions failing to fetch=$historyFails',
        ({ currentFails, historyFails }) => {
          const error = new Error('Network error!');

          beforeEach(async () => {
            currentSubscriptionResolver = currentFails
              ? jest.fn().mockRejectedValue({ error })
              : jest.fn().mockResolvedValue({ data: { currentLicense: license.ULTIMATE } });
            subscriptionHistoryResolver = historyFails
              ? jest.fn().mockRejectedValue({ error })
              : jest.fn().mockResolvedValue({
                  data: { licenseHistoryEntries: { nodes: subscriptionHistory } },
                });

            createComponent({}, [currentSubscriptionResolver, subscriptionHistoryResolver]);
            await waitForPromises();
          });

          it('renders the error alert', () => {
            const alert = findSubscriptionFetchErrorAlert();
            const subscriptionEntryName = historyFails
              ? historySubscriptionsEntryName
              : currentSubscriptionsEntryName;
            expect(alert.exists()).toBe(true);
            expect(alert.props('title')).toBe(subscriptionHistoryFailedTitle);
            expect(alert.text().replace(/\s+/g, ' ')).toBe(
              sprintf(subscriptionHistoryFailedMessage, { subscriptionEntryName }),
            );
          });
        },
      );
    });
  });

  describe('Subscription Activation Form', () => {
    it('shows the main title', () => {
      currentSubscriptionResolver = jest
        .fn()
        .mockResolvedValue({ data: { currentLicense: license.ULTIMATE } });
      subscriptionHistoryResolver = jest
        .fn()
        .mockResolvedValue({ data: { licenseHistoryEntries: { nodes: subscriptionHistory } } });
      createComponent({}, [currentSubscriptionResolver, subscriptionHistoryResolver]);
      expect(findSubscriptionMainTitle().text()).toBe(subscriptionMainTitle);
    });

    describe('without an active license', () => {
      beforeEach(() => {
        currentSubscriptionResolver = jest
          .fn()
          .mockResolvedValue({ data: { currentLicense: null } });
        subscriptionHistoryResolver = jest
          .fn()
          .mockResolvedValue({ data: { licenseHistoryEntries: { nodes: [] } } });
        createComponent({}, [currentSubscriptionResolver, subscriptionHistoryResolver]);
      });
      it('shows a title saying there is no active subscription', () => {
        expect(findSubscriptionActivationTitle().text()).toBe(noActiveSubscription);
      });

      it('queries for the current history', () => {
        expect(subscriptionHistoryResolver).toHaveBeenCalledTimes(1);
      });

      it('shows the subscription activation form', () => {
        expect(findActivateSubscriptionCard().exists()).toBe(true);
      });

      it('does not show the activation success notification', () => {
        expect(findSubscriptionActivationSuccessAlert().exists()).toBe(false);
      });

      it('does not render the "Export license usage file" link', () => {
        expect(findExportLicenseUsageFileLink().exists()).toBe(false);
      });

      describe('activating the license', () => {
        it('shows the activation success notification', async () => {
          await findActivateSubscriptionCard().vm.$emit(
            SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
            license.ULTIMATE,
          );
          expect(findSubscriptionActivationSuccessAlert().props('title')).toBe(
            subscriptionActivationNotificationText,
          );
        });

        it('shows the future dated activation success notification', async () => {
          await findActivateSubscriptionCard().vm.$emit(
            SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
            license.ULTIMATE_FUTURE_DATED,
          );
          expect(findSubscriptionActivationSuccessAlert().props('title')).toBe(
            subscriptionActivationFutureDatedNotificationTitle,
          );
        });
      });
    });

    describe('activating the license', () => {
      beforeEach(() => {
        currentSubscriptionResolver = jest
          .fn()
          .mockResolvedValue({ data: { currentLicense: license.ULTIMATE } });
        subscriptionHistoryResolver = jest
          .fn()
          .mockResolvedValue({ data: { licenseHistoryEntries: { nodes: subscriptionHistory } } });
        createComponent({ hasActiveLicense: false }, [
          currentSubscriptionResolver,
          subscriptionHistoryResolver,
        ]);
      });

      it('passes the correct data to the subscription breakdown', () => {
        expect(findSubscriptionBreakdown().props()).toMatchObject({
          subscription: license.ULTIMATE,
          subscriptionList: subscriptionHistory,
        });
      });

      it('shows the activation success notification', async () => {
        await findSubscriptionBreakdown().vm.$emit(
          SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
          license.ULTIMATE,
        );
        expect(findSubscriptionActivationSuccessAlert().props('title')).toBe(
          subscriptionActivationNotificationText,
        );
      });

      it('shows the future dated activation success notification', async () => {
        await findSubscriptionBreakdown().vm.$emit(
          SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
          license.ULTIMATE_FUTURE_DATED,
        );
        expect(findSubscriptionActivationSuccessAlert().props('title')).toBe(
          subscriptionActivationFutureDatedNotificationTitle,
        );
      });
    });

    describe('with active license', () => {
      beforeEach(() => {
        currentSubscriptionResolver = jest
          .fn()
          .mockResolvedValue({ data: { currentLicense: license.ULTIMATE } });
        subscriptionHistoryResolver = jest
          .fn()
          .mockResolvedValue({ data: { licenseHistoryEntries: { nodes: subscriptionHistory } } });
        createComponent({ hasActiveLicense: true }, [
          currentSubscriptionResolver,
          subscriptionHistoryResolver,
        ]);
      });

      it('queries for the current license', () => {
        expect(currentSubscriptionResolver).toHaveBeenCalledTimes(1);
      });

      it('queries for the current history', () => {
        expect(subscriptionHistoryResolver).toHaveBeenCalledTimes(1);
      });

      it('passes the correct data to the subscription breakdown', () => {
        expect(findSubscriptionBreakdown().props()).toMatchObject({
          subscription: license.ULTIMATE,
          subscriptionList: subscriptionHistory,
        });
      });

      it('does not the activation success notification', () => {
        expect(findSubscriptionActivationSuccessAlert().exists()).toBe(false);
      });

      it('renders the "Export license usage file" link', () => {
        expect(findExportLicenseUsageFileLink().exists()).toBe(true);
      });
    });
  });
});
