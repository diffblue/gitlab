import { GlButton } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import SubscriptionManagementApp from 'ee/admin/subscriptions/show/components/app.vue';
import SubscriptionActivationCard from 'ee/admin/subscriptions/show/components/subscription_activation_card.vue';
import SubscriptionBreakdown from 'ee/admin/subscriptions/show/components/subscription_breakdown.vue';

import {
  noActiveSubscription,
  subscriptionActivationNotificationText,
  subscriptionHistoryQueries,
  subscriptionMainTitle,
  subscriptionQueries,
} from 'ee/admin/subscriptions/show/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { license, subscriptionHistory } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('SubscriptionManagementApp', () => {
  let wrapper;

  const findActivateSubscriptionCard = () => wrapper.findComponent(SubscriptionActivationCard);
  const findSubscriptionBreakdown = () => wrapper.findComponent(SubscriptionBreakdown);
  const findSubscriptionActivationTitle = () =>
    wrapper.findByTestId('subscription-activation-title');
  const findSubscriptionMainTitle = () => wrapper.findByTestId('subscription-main-title');
  const findSubscriptionActivationSuccessAlert = () =>
    wrapper.findByTestId('subscription-activation-success-alert');
  const findExportLicenseUsageFileLink = () => wrapper.findComponent(GlButton);

  let currentSubscriptionResolver;
  let subscriptionHistoryResolver;
  const createMockApolloProvider = ([subscriptionResolver, historyResolver]) => {
    localVue.use(VueApollo);
    return createMockApollo([
      [subscriptionQueries.query, subscriptionResolver],
      [subscriptionHistoryQueries.query, historyResolver],
    ]);
  };

  const createComponent = (props = {}, resolverMock) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionManagementApp, {
        localVue,
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          licenseUsageFilePath: 'about:blank',
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
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

      it('shows the activation success notification', () => {
        expect(findSubscriptionActivationSuccessAlert().props('title')).toBe(
          subscriptionActivationNotificationText,
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
