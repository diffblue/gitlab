import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import SubscriptionManagementApp from 'ee/admin/subscriptions/show/components/app.vue';
import SubscriptionBreakdown from 'ee/admin/subscriptions/show/components/subscription_breakdown.vue';
import NoActiveSubscription from 'ee_else_ce/admin/subscriptions/show/components/no_active_subscription.vue';
import {
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
import {
  makeSubscriptionFutureEntry,
  license,
  subscriptionPastHistory,
  subscriptionFutureHistory,
} from '../mock_data';

Vue.use(VueApollo);

const currentResponseWithData = {
  data: { currentLicense: { __typename: 'CurrentLicense', ...license.ULTIMATE } },
};
const currentLicenseEmpty = { data: { currentLicense: null } };
const futureResponseEmpty = { data: { subscriptionFutureEntries: { nodes: [] } } };
const futureResponseWithData = {
  data: {
    subscriptionFutureEntries: {
      nodes: subscriptionFutureHistory.map(makeSubscriptionFutureEntry),
    },
  },
};
const pastResponseWithData = {
  data: { licenseHistoryEntries: { nodes: subscriptionPastHistory } },
};

describe('SubscriptionManagementApp', () => {
  // March 16th, 2021
  useFakeDate(2021, 2, 16);

  let wrapper;

  const findSubscriptionBreakdown = () => wrapper.findComponent(SubscriptionBreakdown);
  const findNoActiveSubscription = () => wrapper.findComponent(NoActiveSubscription);
  const findSubscriptionMainTitle = () => wrapper.findByTestId('subscription-main-title');
  const findSubscriptionActivationSuccessAlert = () =>
    wrapper.findByTestId('subscription-activation-success-alert');
  const findSubscriptionFetchErrorAlert = () =>
    wrapper.findByTestId('subscription-fetch-error-alert');
  const findExportLicenseUsageFileLink = () => wrapper.findByTestId('export-license-usage-btn');
  const findCustomersPortalBtn = () => wrapper.findByTestId('customers-portal-btn');

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
        provide: {
          customersPortalUrl: 'url.com',
        },
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

  describe('when subscription fetch is successful', () => {
    beforeEach(() => {
      currentSubscriptionResolver = jest.fn().mockResolvedValue(currentResponseWithData);
      pastSubscriptionsResolver = jest.fn().mockResolvedValue(pastResponseWithData);
      futureSubscriptionsResolver = jest.fn().mockResolvedValue(futureResponseEmpty);
      createComponent({}, [
        currentSubscriptionResolver,
        pastSubscriptionsResolver,
        futureSubscriptionsResolver,
      ]);
    });

    it('shows the main title', () => {
      expect(findSubscriptionMainTitle().text()).toBe(subscriptionMainTitle);
    });

    it('shows the customers portal button', () => {
      expect(findCustomersPortalBtn().exists()).toBe(true);
    });
  });

  describe('when failing to fetch subscriptions', () => {
    describe('when failing to fetch history subscriptions', () => {
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
              : jest.fn().mockResolvedValue(currentResponseWithData);
            pastSubscriptionsResolver = pastFails
              ? jest.fn().mockRejectedValue({ error })
              : jest.fn().mockResolvedValue(pastResponseWithData);
            futureSubscriptionsResolver = futureFails
              ? jest.fn().mockRejectedValue({ error })
              : jest.fn().mockResolvedValue(futureResponseEmpty);

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

  it('shows the main title', () => {
    currentSubscriptionResolver = jest.fn().mockResolvedValue(currentResponseWithData);
    pastSubscriptionsResolver = jest.fn().mockResolvedValue(pastResponseWithData);
    futureSubscriptionsResolver = jest.fn().mockResolvedValue(futureResponseEmpty);
    createComponent({}, [
      currentSubscriptionResolver,
      pastSubscriptionsResolver,
      futureSubscriptionsResolver,
    ]);
    expect(findSubscriptionMainTitle().text()).toBe(subscriptionMainTitle);
  });

  describe('Subscription Activation Form', () => {
    describe('without an active license', () => {
      describe('without future subscriptions', () => {
        beforeEach(async () => {
          currentSubscriptionResolver = jest.fn().mockResolvedValue(currentLicenseEmpty);
          pastSubscriptionsResolver = jest.fn().mockResolvedValue(pastResponseWithData);
          futureSubscriptionsResolver = jest.fn().mockResolvedValue(futureResponseEmpty);
          createComponent({ hasActiveLicense: false }, [
            currentSubscriptionResolver,
            pastSubscriptionsResolver,
            futureSubscriptionsResolver,
          ]);
          await waitForPromises();
        });

        it('shows the no active subscription state', () => {
          expect(findNoActiveSubscription().exists()).toBe(true);
        });

        it('passes only the past history to the no subscription state', () => {
          expect(findNoActiveSubscription().props()).toMatchObject({
            subscriptionList: subscriptionPastHistory,
          });
        });

        it('queries for the past history', () => {
          expect(pastSubscriptionsResolver).toHaveBeenCalledTimes(1);
        });

        it('queries for the future history', () => {
          expect(futureSubscriptionsResolver).toHaveBeenCalledTimes(1);
        });

        it('does not show the activation success notification', () => {
          expect(findSubscriptionActivationSuccessAlert().exists()).toBe(false);
        });

        it('does not render the "Export license usage file" link', () => {
          expect(findExportLicenseUsageFileLink().exists()).toBe(false);
        });

        describe('activating the license', () => {
          it('shows the activation success notification', async () => {
            findNoActiveSubscription().vm.$emit(
              SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
              license.ULTIMATE,
            );
            await nextTick();

            expect(findSubscriptionActivationSuccessAlert().props('title')).toBe(
              subscriptionActivationNotificationText,
            );
          });

          it('shows the future dated activation success notification', async () => {
            findNoActiveSubscription().vm.$emit(
              SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
              license.ULTIMATE_FUTURE_DATED,
            );
            await nextTick();

            expect(findSubscriptionActivationSuccessAlert().props('title')).toBe(
              subscriptionActivationFutureDatedNotificationTitle,
            );
          });
        });
      });

      describe('with future subscriptions', () => {
        beforeEach(async () => {
          currentSubscriptionResolver = jest.fn().mockResolvedValue(currentLicenseEmpty);
          pastSubscriptionsResolver = jest.fn().mockResolvedValue(pastResponseWithData);
          futureSubscriptionsResolver = jest.fn().mockResolvedValue(futureResponseWithData);
          createComponent({ hasActiveLicense: false }, [
            currentSubscriptionResolver,
            pastSubscriptionsResolver,
            futureSubscriptionsResolver,
          ]);
          await waitForPromises();
        });

        it('passes correct data to the no subscription state', () => {
          expect(findNoActiveSubscription().props()).toMatchObject({
            subscriptionList: [...subscriptionFutureHistory, ...subscriptionPastHistory],
          });
        });
      });
    });

    describe('activating the license', () => {
      beforeEach(async () => {
        currentSubscriptionResolver = jest.fn().mockResolvedValue(currentResponseWithData);
        pastSubscriptionsResolver = jest.fn().mockResolvedValue(pastResponseWithData);
        futureSubscriptionsResolver = jest.fn().mockResolvedValue(futureResponseEmpty);
        createComponent({ hasActiveLicense: false }, [
          currentSubscriptionResolver,
          pastSubscriptionsResolver,
          futureSubscriptionsResolver,
        ]);
        jest
          .spyOn(wrapper.vm.$apollo.queries.currentSubscription, 'refetch')
          .mockImplementation(jest.fn());
        jest
          .spyOn(wrapper.vm.$apollo.queries.pastLicenseHistoryEntries, 'refetch')
          .mockImplementation(jest.fn());
        jest
          .spyOn(wrapper.vm.$apollo.queries.futureLicenseHistoryEntries, 'refetch')
          .mockImplementation(jest.fn());
        await waitForPromises();
      });

      it('passes the correct data to the subscription breakdown', () => {
        expect(findSubscriptionBreakdown().props()).toMatchObject({
          subscription: license.ULTIMATE,
          subscriptionList: subscriptionPastHistory,
        });
      });

      it('shows the activation success notification', async () => {
        findSubscriptionBreakdown().vm.$emit(
          SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
          license.ULTIMATE,
        );
        await nextTick();

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

      it('calls refetch to update local state', async () => {
        findSubscriptionBreakdown().vm.$emit(
          SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
          license.ULTIMATE_FUTURE_DATED,
        );
        await nextTick();

        expect(wrapper.vm.$apollo.queries.currentSubscription.refetch).toHaveBeenCalledTimes(1);
        expect(wrapper.vm.$apollo.queries.pastLicenseHistoryEntries.refetch).toHaveBeenCalledTimes(
          1,
        );
        expect(
          wrapper.vm.$apollo.queries.futureLicenseHistoryEntries.refetch,
        ).toHaveBeenCalledTimes(1);
      });
    });

    describe('with active license', () => {
      beforeEach(() => {
        currentSubscriptionResolver = jest.fn().mockResolvedValue(currentResponseWithData);
        pastSubscriptionsResolver = jest.fn().mockResolvedValue(pastResponseWithData);
      });

      describe('without future subscriptions', () => {
        beforeEach(async () => {
          futureSubscriptionsResolver = jest.fn().mockResolvedValue(futureResponseEmpty);
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
            subscriptionList: subscriptionPastHistory,
          });
        });

        it('does not show the activation success notification', () => {
          expect(findSubscriptionActivationSuccessAlert().exists()).toBe(false);
        });

        it('renders the "Export license usage file" link', () => {
          expect(findExportLicenseUsageFileLink().exists()).toBe(true);
        });
      });

      describe('with future subscriptions', () => {
        beforeEach(async () => {
          futureSubscriptionsResolver = jest.fn().mockResolvedValue(futureResponseWithData);
          createComponent({ hasActiveLicense: true }, [
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
      });
    });
  });
});
