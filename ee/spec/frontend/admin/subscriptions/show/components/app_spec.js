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
  pastSubscriptionsEntryName,
  futureSubscriptionsEntryName,
  subscriptionMainTitle,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
} from 'ee/admin/subscriptions/show/constants';
import getCurrentLicense from 'ee/admin/subscriptions/show/graphql/queries/get_current_license.query.graphql';
import getPastLicenseHistory from 'ee/admin/subscriptions/show/graphql/queries/get_past_license_history.query.graphql';
import getFutureLicenseHistory from 'ee/admin/subscriptions/show/graphql/queries/get_future_license_history.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import { license, subscriptionPastHistory, subscriptionFutureHistory } from '../mock_data';

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
  let pastSubscriptionsResolver;
  let futureSubscriptionsResolver;
  const createMockApolloProvider = ([currentResolver, pastResolver, futureResolver]) => {
    Vue.use(VueApollo);
    return createMockApollo([
      [getCurrentLicense, currentResolver],
      [getPastLicenseHistory, pastResolver],
      [getFutureLicenseHistory, futureResolver],
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
        currentFails | pastFails | futureFails
        ${true}      | ${false}  | ${false}
        ${false}     | ${true}   | ${false}
        ${false}     | ${false}  | ${true}
        ${true}      | ${true}   | ${false}
        ${false}     | ${true}   | ${true}
        ${true}      | ${false}  | ${true}
        ${true}      | ${true}   | ${true}
      `(
        'with current subscription fetch failing: currentFails=$currentFails, pastFails=$pastFails, and futureFails=$futureFails',
        ({ currentFails, pastFails, futureFails }) => {
          const error = new Error('Network error!');

          beforeEach(async () => {
            currentSubscriptionResolver = currentFails
              ? jest.fn().mockRejectedValue({ error })
              : jest.fn().mockResolvedValue({ data: { currentLicense: license.ULTIMATE } });
            pastSubscriptionsResolver = pastFails
              ? jest.fn().mockRejectedValue({ error })
              : jest.fn().mockResolvedValue({
                  data: { licenseHistoryEntries: { nodes: subscriptionPastHistory } },
                });
            futureSubscriptionsResolver = futureFails
              ? jest.fn().mockRejectedValue({ error })
              : jest.fn().mockResolvedValue({
                  data: { subscriptionFutureEntries: { nodes: subscriptionFutureHistory } },
                });

            createComponent({}, [
              currentSubscriptionResolver,
              pastSubscriptionsResolver,
              futureSubscriptionsResolver,
            ]);
            await waitForPromises();
          });

          it('renders the error alert', () => {
            const alert = findSubscriptionFetchErrorAlert();
            let subscriptionEntryName;
            if (currentFails) {
              subscriptionEntryName = currentSubscriptionsEntryName;
            }
            if (pastFails) {
              subscriptionEntryName = pastSubscriptionsEntryName;
            }
            if (futureFails) {
              subscriptionEntryName = futureSubscriptionsEntryName;
            }
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
      pastSubscriptionsResolver = jest.fn().mockResolvedValue({
        data: { licenseHistoryEntries: { nodes: subscriptionPastHistory } },
      });
      futureSubscriptionsResolver = jest.fn().mockResolvedValue({
        data: { subscriptionFutureEntries: { nodes: subscriptionFutureHistory } },
      });
      createComponent({}, [
        currentSubscriptionResolver,
        pastSubscriptionsResolver,
        futureSubscriptionsResolver,
      ]);
      expect(findSubscriptionMainTitle().text()).toBe(subscriptionMainTitle);
    });

    describe('without an active license', () => {
      beforeEach(() => {
        currentSubscriptionResolver = jest
          .fn()
          .mockResolvedValue({ data: { currentLicense: null } });
        pastSubscriptionsResolver = jest
          .fn()
          .mockResolvedValue({ data: { licenseHistoryEntries: { nodes: [] } } });
        futureSubscriptionsResolver = jest
          .fn()
          .mockResolvedValue({ data: { subscriptionFutureEntries: { nodes: [] } } });
        createComponent({}, [
          currentSubscriptionResolver,
          pastSubscriptionsResolver,
          futureSubscriptionsResolver,
        ]);
      });

      it('shows a title saying there is no active subscription', () => {
        expect(findSubscriptionActivationTitle().text()).toBe(noActiveSubscription);
      });

      it('queries for the past history', () => {
        expect(pastSubscriptionsResolver).toHaveBeenCalledTimes(1);
      });

      it('queries for the future history', () => {
        expect(futureSubscriptionsResolver).toHaveBeenCalledTimes(1);
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
      beforeEach(async () => {
        currentSubscriptionResolver = jest
          .fn()
          .mockResolvedValue({ data: { currentLicense: license.ULTIMATE } });
        pastSubscriptionsResolver = jest.fn().mockResolvedValue({
          data: { licenseHistoryEntries: { nodes: subscriptionPastHistory } },
        });
        futureSubscriptionsResolver = jest.fn().mockResolvedValue({
          data: { subscriptionFutureEntries: { nodes: subscriptionFutureHistory } },
        });
        createComponent({ hasActiveLicense: false }, [
          currentSubscriptionResolver,
          pastSubscriptionsResolver,
          futureSubscriptionsResolver,
        ]);
        await waitForPromises();
      });

      it('passes the correct data to the subscription breakdown', () => {
        expect(findSubscriptionBreakdown().props()).toMatchObject({
          subscription: license.ULTIMATE,
          subscriptionList: [...subscriptionFutureHistory, ...subscriptionPastHistory],
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
      beforeEach(async () => {
        currentSubscriptionResolver = jest
          .fn()
          .mockResolvedValue({ data: { currentLicense: license.ULTIMATE } });
        pastSubscriptionsResolver = jest.fn().mockResolvedValue({
          data: { licenseHistoryEntries: { nodes: subscriptionPastHistory } },
        });
        futureSubscriptionsResolver = jest.fn().mockResolvedValue({
          data: { subscriptionFutureEntries: { nodes: subscriptionFutureHistory } },
        });
        createComponent({ hasActiveLicense: true }, [
          currentSubscriptionResolver,
          pastSubscriptionsResolver,
          futureSubscriptionsResolver,
        ]);
        await waitForPromises();
      });

      it('queries for the current license', () => {
        expect(currentSubscriptionResolver).toHaveBeenCalledTimes(1);
      });

      it('queries for the past history', () => {
        expect(pastSubscriptionsResolver).toHaveBeenCalledTimes(1);
      });

      it('queries for the future history', () => {
        expect(futureSubscriptionsResolver).toHaveBeenCalledTimes(1);
      });

      it('passes the correct data to the subscription breakdown', () => {
        expect(findSubscriptionBreakdown().props()).toMatchObject({
          subscription: license.ULTIMATE,
          subscriptionList: [...subscriptionFutureHistory, ...subscriptionPastHistory],
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
