import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import AnalyticsApp from 'ee/product_analytics/product_analytics_app.vue';
import OnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import DashboardsView from 'ee/product_analytics/dashboards/dashboards_view.vue';
import createRouter from 'ee/product_analytics/router';
import waitForPromises from 'helpers/wait_for_promises';

describe('ProductAnalyticsApp', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findOnboardingView = () => wrapper.findComponent(OnboardingView);
  const findDashboardsView = () => wrapper.findComponent(DashboardsView);

  const createWrapper = (data = {}) => {
    wrapper = shallowMount(AnalyticsApp, {
      router: createRouter(),
      provide: {
        jitsuKey: '123',
      },
      data() {
        return {
          isLoading: false,
          isOnboarding: false,
          ...data,
        };
      },
    });
  };

  describe('when mounted', () => {
    it('shows the loading icon if loading', () => {
      createWrapper({ isLoading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('should show the onboarding app if onboarding is ongoing', async () => {
      createWrapper({ isOnboarding: true });

      await waitForPromises();

      expect(findOnboardingView().exists()).toBe(true);
    });

    it('should show the dashboards app if onboarding is complete', async () => {
      createWrapper();

      await waitForPromises();

      expect(findDashboardsView().exists()).toBe(true);
    });
  });
});
