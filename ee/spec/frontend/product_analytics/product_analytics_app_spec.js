import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsApp from 'ee/product_analytics/product_analytics_app.vue';
import OnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import DashboardsView from 'ee/analytics/analytics_dashboards/dashboards_app.vue';
import createRouter from 'ee/analytics/analytics_dashboards/router';
import { TEST_HOST } from 'helpers/test_constants';
import {
  TEST_JITSU_KEY,
  TEST_COLLECTOR_HOST,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import { TEST_PROJECT_FULL_PATH, TEST_PROJECT_ID } from './mock_data';

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
        collectorHost: TEST_COLLECTOR_HOST,
        projectFullPath: TEST_PROJECT_FULL_PATH,
        ...provided,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the onboarding view', () => {
      expect(findOnboardingView().exists()).toBe(true);
    });

    it('does not render the dashboard view', () => {
      expect(findDashboardsView().exists()).toBe(false);
    });

    describe('and the onboarding is complete', () => {
      beforeEach(() => {
        findOnboardingView().vm.$emit('complete');
        return nextTick();
      });

      it('renders the dashboard app', () => {
        expect(findDashboardsView().exists()).toBe(true);
      });

      it('does not render the onboarding view', () => {
        expect(findOnboardingView().exists()).toBe(false);
      });
    });
  });
});
