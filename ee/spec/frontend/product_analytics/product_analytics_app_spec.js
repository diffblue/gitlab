import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsApp from 'ee/product_analytics/product_analytics_app.vue';
import OnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import DashboardsView from 'ee/product_analytics/dashboards/dashboards_view.vue';
import createRouter from 'ee/product_analytics/router';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'helpers/test_constants';
import { NO_INSTANCE_DATA, NO_PROJECT_INSTANCE } from 'ee/product_analytics/onboarding/constants';
import {
  TEST_JITSU_KEY,
  TEST_JITSU_HOST,
  TEST_JITSU_PROJECT_ID,
  TEST_PROJECT_FULL_PATH,
  TEST_PROJECT_ID,
} from './mock_data';

jest.mock('ee/product_analytics/dashboards/data_sources/cube_analytics', () => ({
  hasAnalyticsData: jest.fn(),
}));
jest.mock('~/flash');

describe('ProductAnalyticsApp', () => {
  let wrapper;

  const findOnboardingView = () => wrapper.findComponent(OnboardingView);
  const findDashboardsView = () => wrapper.findComponent(DashboardsView);

  const createWrapper = (provided = {}) => {
    wrapper = shallowMountExtended(AnalyticsApp, {
      router: createRouter(),
      provide: {
        chartEmptyStateIllustrationPath: TEST_HOST,
        jitsuKey: TEST_JITSU_KEY,
        projectId: TEST_PROJECT_ID,
        jitsuHost: TEST_JITSU_HOST,
        jitsuProjectId: TEST_JITSU_PROJECT_ID,
        projectFullPath: TEST_PROJECT_FULL_PATH,
        ...provided,
      },
    });
  };

  describe('when mounted', () => {
    it('should show the onboarding app if there is no jitsuKey', async () => {
      createWrapper({ jitsuKey: null });

      await waitForPromises();

      expect(findOnboardingView().props('status')).toBe(NO_PROJECT_INSTANCE);
      expect(findDashboardsView().exists()).toBe(false);
    });

    it('should show the dashboards app if the onboarding was successful', async () => {
      createWrapper({ jitsuKey: null });

      await waitForPromises();

      findOnboardingView().vm.$emit('complete');

      await waitForPromises();

      expect(findDashboardsView().exists()).toBe(true);
    });

    it('should show onboarding view with NO_INSTANCE_DATA status with a jitsuKey', async () => {
      createWrapper();

      expect(findOnboardingView().props('status')).toBe(NO_INSTANCE_DATA);
    });
  });
});
