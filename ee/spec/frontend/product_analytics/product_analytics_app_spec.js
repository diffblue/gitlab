import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import AnalyticsApp from 'ee/product_analytics/product_analytics_app.vue';
import OnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import DashboardsView from 'ee/product_analytics/dashboards/dashboards_view.vue';
import createRouter from 'ee/product_analytics/router';
import waitForPromises from 'helpers/wait_for_promises';
import cubeAnalytics from 'ee/product_analytics/dashboards/data_sources/cube_analytics';
import { TEST_HOST } from 'helpers/test_constants';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';

jest.mock('ee/product_analytics/dashboards/data_sources/cube_analytics', () => ({
  hasAnalyticsData: jest.fn(),
}));
jest.mock('~/flash');

describe('ProductAnalyticsApp', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findOnboardingView = () => wrapper.findComponent(OnboardingView);
  const findDashboardsView = () => wrapper.findComponent(DashboardsView);

  const createWrapper = (provided = {}) => {
    wrapper = shallowMount(AnalyticsApp, {
      router: createRouter(),
      provide: {
        jitsuKey: '123',
        projectId: '1',
        chartEmptyStateIllustrationPath: TEST_HOST,
        ...provided,
      },
    });
  };

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when mounted', () => {
    it('shows the loading icon if loading', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('should show the onboarding app if there is no jitsuKey', async () => {
      createWrapper({ jitsuKey: null });

      await waitForPromises();

      expect(findOnboardingView().exists()).toBe(true);
    });

    // Cube.js passes errors using a custom error type
    // In these tests we're mocking the output of that type
    // https://github.com/cube-js/cube.js/blob/master/packages/cubejs-client-core/src/RequestError.js
    it('should show the alert if there is an unhandled error', async () => {
      const error = { response: { message: 'unknown error' } };

      jest.spyOn(cubeAnalytics, 'hasAnalyticsData').mockRejectedValue(error);

      createWrapper();

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: s__(
          'ProductAnalytics|An error occurred while fetching data. Refresh the page to try again.',
        ),
        captureError: true,
        error,
      });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findOnboardingView().exists()).toBe(false);
      expect(findDashboardsView().exists()).toBe(false);
    });

    it('should show the onboarding app if there is no analytics data', async () => {
      jest.spyOn(cubeAnalytics, 'hasAnalyticsData').mockReturnValue(false);

      createWrapper();

      await waitForPromises();

      expect(findOnboardingView().exists()).toBe(true);
    });

    it('should show the dashboards app if there is analytics data', async () => {
      jest.spyOn(cubeAnalytics, 'hasAnalyticsData').mockReturnValue(true);

      createWrapper();

      await waitForPromises();

      expect(findDashboardsView().exists()).toBe(true);
    });
  });
});
